import 'package:cloud_firestore/cloud_firestore.dart';

/// 아이 성별. Firestore에는 wire 값('M'|'F')으로 저장한다.
enum Sex {
  male('M'),
  female('F');

  const Sex(this.wire);
  final String wire;

  static Sex? fromWire(String? value) {
    for (final s in Sex.values) {
      if (s.wire == value) return s;
    }
    return null;
  }
}

/// 아이. Firestore `children/{childId}` 문서. 아이 1명당 그룹 1개([FamilyGroup]).
///
/// 주민등록번호(RRN)는 평문/마스킹을 절대 저장하지 않고 [rrnEncrypted](암호문)만 둔다.
/// 전체 값은 재인증 후 [RrnCipher]로만 복호화한다(일반 조회 쿼리에 평문을 싣지 않음).
class Child {
  const Child({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.sex,
    this.bloodType,
    this.rrnEncrypted,
    this.notes,
    this.photoUrl,
  });

  /// 문서 ID(본문에는 저장하지 않음).
  final String id;
  final String name;
  final DateTime birthDate;
  final Sex sex;

  /// 혈액형(예: "A", "O", "RH+B"). 자유 입력이라 String으로 둔다.
  final String? bloodType;

  /// 암호화된 주민등록번호. 평문/마스킹 텍스트를 여기에 넣지 않는다.
  final String? rrnEncrypted;

  /// 특이사항.
  final String? notes;

  /// 프로필 사진 다운로드 URL. Storage `children/{groupId}/...`에 업로드한다.
  final String? photoUrl;

  factory Child.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Child(
      id: doc.id,
      name: data['name'] as String? ?? '',
      birthDate:
          (data['birthDate'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sex: Sex.fromWire(data['sex'] as String?) ?? Sex.male,
      bloodType: data['bloodType'] as String?,
      rrnEncrypted: data['rrnEncrypted'] as String?,
      notes: data['notes'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'birthDate': Timestamp.fromDate(birthDate),
    'sex': sex.wire,
    'bloodType': bloodType,
    'rrnEncrypted': rrnEncrypted,
    'notes': notes,
    'photoUrl': photoUrl,
  };

  Child copyWith({
    String? name,
    DateTime? birthDate,
    Sex? sex,
    String? bloodType,
    String? rrnEncrypted,
    String? notes,
    String? photoUrl,
  }) {
    return Child(
      id: id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      bloodType: bloodType ?? this.bloodType,
      rrnEncrypted: rrnEncrypted ?? this.rrnEncrypted,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
