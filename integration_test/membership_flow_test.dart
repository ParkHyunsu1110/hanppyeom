import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/firebase_options.dart';
import 'package:hanppyeom/models/models.dart';
import 'package:hanppyeom/repositories/group_repository.dart';
import 'package:hanppyeom/repositories/membership_repository.dart';
import 'package:hanppyeom/services/auth_service.dart';
import 'package:integration_test/integration_test.dart';

/// Firebase Local Emulator Suite에 붙여 Phase 1 멤버십 흐름을 실기기에서 검증한다.
///
/// 실행(Android/iOS 실기기·에뮬레이터 권장):
///   firebase emulators:start --only auth,firestore --project hanppyeom
///   flutter test integration_test/membership_flow_test.dart -d <device>
///
/// ⚠️ macOS 데스크톱(-d macos)은 firebase_core의 default FIRApp 중복 configure
/// 이슈로 기동 시 네이티브 abort가 난다(앱 로직 문제 아님). 규칙 자체 검증은
/// 플랫폼 독립적인 `test/firestore_rules/`(Node) 스크립트를 쓴다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseAuth auth;
  late FirebaseFirestore fs;
  late AuthService authService;
  late GroupRepository groupRepo;
  late MembershipRepository memberRepo;

  setUpAll(() async {
    // 이미 초기화돼 있으면 재초기화하지 않는다(중복 configure 시 네이티브 abort).
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    }
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

    auth = FirebaseAuth.instance;
    fs = FirebaseFirestore.instance;
    authService = AuthService(auth: auth, firestore: fs);
    groupRepo = GroupRepository(firestore: fs);
    memberRepo = MembershipRepository(firestore: fs);
  });

  // 매 실행 고유 이메일(에뮬레이터 데이터 잔존 대비).
  final tag = DateTime.now().microsecondsSinceEpoch;
  final parentEmail = 'parent.$tag@test.com';
  final auntEmail = 'aunt.$tag@test.com';
  const password = 'pw123456';

  testWidgets('멤버십 게이트 end-to-end (창립→초대→PENDING차단→승인→읽기→쓰기차단)',
      (tester) async {
    // 1. 부모 가입 + 아이/그룹 창립
    final parent = await authService.signUp(
      email: parentEmail,
      password: password,
      displayName: '엄마',
    );
    final groupId = await groupRepo.createChildWithGroup(
      founderUid: parent.id,
      child: Child(
        id: '',
        name: '도윤',
        birthDate: DateTime(2024, 3, 15),
        sex: Sex.male,
      ),
      relationLabel: '엄마',
    );

    // 부모는 그룹/아이 읽기 성공
    final group = await groupRepo.getGroup(groupId);
    expect(group, isNotNull);
    expect((await groupRepo.getChild(groupId))!.name, '도윤');
    final code = group!.inviteCode;

    // 2. 친척 가입 + 초대 코드로 참여(PENDING)
    await auth.signOut();
    final aunt = await authService.signUp(
      email: auntEmail,
      password: password,
      displayName: '이모',
    );
    await memberRepo.joinByInviteCode(
      uid: aunt.id,
      code: code,
      relationLabel: '이모',
    );

    // 3. PENDING 상태에서는 그룹/아이 읽기 차단(규칙)
    await expectLater(
      groupRepo.getGroup(groupId),
      throwsA(isA<FirebaseException>()),
    );
    await expectLater(
      groupRepo.getChild(groupId),
      throwsA(isA<FirebaseException>()),
    );

    // 4. 부모가 승인(PENDING→ACTIVE)
    await auth.signOut();
    await authService.signIn(email: parentEmail, password: password);
    await memberRepo.approve(Membership.docId(groupId, aunt.id));

    // 5. 친척 재로그인 → 읽기 허용
    await auth.signOut();
    await authService.signIn(email: auntEmail, password: password);
    expect(await groupRepo.getGroup(groupId), isNotNull);
    expect((await groupRepo.getChild(groupId))!.name, '도윤');

    // 6. 친척(RELATIVE)은 아이 정보 쓰기 차단(규칙)
    await expectLater(
      fs.collection('children').doc(groupId).update({'notes': '시도'}),
      throwsA(isA<FirebaseException>()),
    );
  });
}
