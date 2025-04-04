class Employee {
  final int employeeId;
  final int staffId;
  final String position;
  final DateTime hireDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.employeeId,
    required this.staffId,
    required this.position,
    required this.hireDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employee_id'],
      staffId: json['staff_id'],
      position: json['position'],
      hireDate: DateTime.parse(json['hire_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}