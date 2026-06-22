/// Repository 레이어 공용 예외. UI에서 사용자 메시지로 변환하기 쉽게 분리한다.
sealed class RepositoryException implements Exception {
  const RepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 입력한 초대 코드에 해당하는 그룹이 없을 때.
class InviteCodeNotFoundException extends RepositoryException {
  const InviteCodeNotFoundException(this.code) : super('초대 코드를 찾을 수 없습니다.');
  final String code;
}

/// 이미 해당 그룹의 멤버이거나 승인 대기 중일 때.
class AlreadyJoinedException extends RepositoryException {
  const AlreadyJoinedException(this.groupId)
    : super('이미 참여 중이거나 승인 대기 중인 아이입니다.');
  final String groupId;
}
