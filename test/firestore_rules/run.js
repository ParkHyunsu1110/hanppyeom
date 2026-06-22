// 한뼘 Firestore 보안 규칙 검증.
// 실행 전제: firebase emulators:start --only auth,firestore --project hanppyeom
// 실행: cd test/firestore_rules && npm install && npm test
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  collection,
  addDoc,
  getDoc,
  setDoc,
  updateDoc,
  writeBatch,
} = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

(async () => {
  const testEnv = await initializeTestEnvironment({
    projectId: 'hanppyeom',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  let failed = 0;
  const ok = async (label, p) => {
    try {
      await assertSucceeds(p);
      console.log('  ✓', label);
    } catch (e) {
      failed++;
      console.log('  ✗', label, '-', e.message);
    }
  };
  const denied = async (label, p) => {
    try {
      await assertFails(p);
      console.log('  ✓ (거부됨)', label);
    } catch (e) {
      failed++;
      console.log('  ✗', label, '(거부 기대했으나 통과) -', e.message);
    }
  };

  const gid = 'g_' + Date.now();
  const code = 'CODE' + Math.floor(Math.random() * 1000);
  const parent = testEnv.authenticatedContext('parent').firestore();
  const aunt = testEnv.authenticatedContext('aunt').firestore();

  console.log('▶ 창립(부모)');
  const b = writeBatch(parent);
  b.set(doc(parent, 'children', gid), { name: '도윤', birthDate: new Date(), sex: 'M' });
  b.set(doc(parent, 'groups', gid), { childId: gid, inviteCode: code });
  b.set(doc(parent, 'memberships', `${gid}_parent`), {
    userId: 'parent', groupId: gid, role: 'PARENT', status: 'ACTIVE', isAdmin: true, relationLabel: '엄마',
  });
  b.set(doc(parent, 'inviteCodes', code), { groupId: gid });
  await ok('부모 창립 배치(child/group/membership/inviteCode)', b.commit());
  await ok('부모가 그룹 읽기', getDoc(doc(parent, 'groups', gid)));
  await ok('부모가 아이 읽기', getDoc(doc(parent, 'children', gid)));

  console.log('▶ 초대 참여(친척)');
  await ok('친척이 inviteCodes 읽기', getDoc(doc(aunt, 'inviteCodes', code)));
  await ok('친척 PENDING 멤버십 생성', setDoc(doc(aunt, 'memberships', `${gid}_aunt`), {
    userId: 'aunt', groupId: gid, role: 'RELATIVE', status: 'PENDING', isAdmin: false, relationLabel: '이모',
  }));

  console.log('▶ PENDING 게이트');
  await denied('PENDING 친척의 그룹 읽기 차단', getDoc(doc(aunt, 'groups', gid)));
  await denied('PENDING 친척의 아이 읽기 차단', getDoc(doc(aunt, 'children', gid)));
  await denied('친척이 스스로 ACTIVE 승인 차단', updateDoc(doc(aunt, 'memberships', `${gid}_aunt`), { status: 'ACTIVE' }));

  console.log('▶ 권한 위반 시도');
  await denied('비멤버의 PARENT 멤버십 자가 생성 차단', setDoc(doc(aunt, 'memberships', `${gid}_aunt2`), {
    userId: 'aunt', groupId: gid, role: 'PARENT', status: 'ACTIVE', isAdmin: true,
  }));

  console.log('▶ 승인 후');
  await ok('관리자 승인(PENDING→ACTIVE)', updateDoc(doc(parent, 'memberships', `${gid}_aunt`), { status: 'ACTIVE' }));
  await ok('승인된 친척 그룹 읽기', getDoc(doc(aunt, 'groups', gid)));
  await ok('승인된 친척 아이 읽기', getDoc(doc(aunt, 'children', gid)));
  await denied('친척(RELATIVE)의 아이 수정 차단', updateDoc(doc(aunt, 'children', gid), { notes: '시도' }));

  console.log('▶ 성장기록 권한');
  const recId = 'rec_' + Date.now();
  await ok('부모(PARENT) 성장기록 생성', setDoc(doc(parent, 'growthRecords', recId), {
    childId: gid, groupId: gid, type: 'HEIGHT', value: 75, date: new Date(), recordedBy: 'parent',
  }));
  await ok('승인된 친척 성장기록 읽기', getDoc(doc(aunt, 'growthRecords', recId)));
  await denied('친척(RELATIVE) 성장기록 생성 차단', setDoc(doc(aunt, 'growthRecords', `${recId}_x`), {
    childId: gid, groupId: gid, type: 'HEIGHT', value: 80, date: new Date(), recordedBy: 'aunt',
  }));
  await denied('성장기록 recordedBy 위조 차단', setDoc(doc(parent, 'growthRecords', `${recId}_y`), {
    childId: gid, groupId: gid, type: 'HEIGHT', value: 80, date: new Date(), recordedBy: 'someoneelse',
  }));

  console.log('▶ 피드 공개범위 (FAMILY/COUPLE 상속)');
  const t = Date.now();
  const famPost = `post_fam_${t}`;
  const couPost = `post_cou_${t}`;
  const mkPost = (vis, author) => ({
    groupId: gid, authorId: author, caption: 'x', photoUrls: [], visibility: vis, createdAt: new Date(),
  });
  await ok('부모 FAMILY 글 작성', setDoc(doc(parent, 'posts', famPost), mkPost('FAMILY', 'parent')));
  await ok('부모 COUPLE 글 작성', setDoc(doc(parent, 'posts', couPost), mkPost('COUPLE', 'parent')));
  await ok('친척 FAMILY 글 읽기', getDoc(doc(aunt, 'posts', famPost)));
  await denied('친척 COUPLE 글 읽기 차단', getDoc(doc(aunt, 'posts', couPost)));
  await ok('친척 FAMILY 글 작성', setDoc(doc(aunt, 'posts', `post_af_${t}`), mkPost('FAMILY', 'aunt')));
  await denied('친척 COUPLE 글 작성 차단', setDoc(doc(aunt, 'posts', `post_ax_${t}`), mkPost('COUPLE', 'aunt')));
  // 좋아요/댓글은 글 공개범위 상속
  await ok('친척 FAMILY 글 좋아요', setDoc(doc(aunt, 'likes', `${famPost}_aunt`), { postId: famPost, userId: 'aunt' }));
  await denied('친척 COUPLE 글 좋아요 차단', setDoc(doc(aunt, 'likes', `${couPost}_aunt`), { postId: couPost, userId: 'aunt' }));
  await ok('친척 FAMILY 글 댓글', addDoc(collection(aunt, 'comments'), { postId: famPost, authorId: 'aunt', text: 'hi', createdAt: new Date() }));
  await denied('친척 COUPLE 글 댓글 차단', addDoc(collection(aunt, 'comments'), { postId: couPost, authorId: 'aunt', text: 'no', createdAt: new Date() }));

  await testEnv.cleanup();
  console.log(failed === 0 ? '\n✅ 모든 규칙 검증 통과' : `\n❌ ${failed}건 실패`);
  process.exit(failed === 0 ? 0 : 1);
})().catch((e) => {
  console.error('스크립트 오류:', e);
  process.exit(2);
});
