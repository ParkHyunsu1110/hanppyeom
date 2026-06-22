import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanppyeom/repositories/chat_repository.dart';

void main() {
  test('send 저장 + watchMessages 시간 오름차순', () async {
    final fs = FakeFirebaseFirestore();
    final repo = ChatRepository(firestore: fs);

    await repo.send(groupId: 'g1', senderId: 'u1', text: '안녕');
    await repo.send(groupId: 'g1', senderId: 'u2', text: '반가워');
    // 다른 그룹 메시지는 섞이지 않음
    await repo.send(groupId: 'g2', senderId: 'u3', text: '다른그룹');

    final msgs = await repo.watchMessages('g1').first;
    expect(msgs.length, 2);
    expect(msgs.first.text, '안녕');
    expect(msgs.last.text, '반가워');
    expect(msgs.every((m) => m.groupId == 'g1'), isTrue);
  });
}
