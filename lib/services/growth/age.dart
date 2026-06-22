/// 생년월일과 측정일로 만 개월수를 계산한다. 음수면 0으로 클램프.
int ageInMonths({required DateTime birthDate, required DateTime at}) {
  var months = (at.year - birthDate.year) * 12 + (at.month - birthDate.month);
  if (at.day < birthDate.day) months -= 1;
  return months < 0 ? 0 : months;
}
