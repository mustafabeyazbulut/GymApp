class Trainer {
  const Trainer({required this.id, required this.fullName, required this.branchId});

  // User.Id - Reservation.trainerId/CreateReservation'ın trainerId'si bu
  // değere referans verir, bir Assignment id'sine değil.
  final int id;
  final String fullName;
  final int? branchId;

  factory Trainer.fromJson(Map<String, dynamic> json) => Trainer(
        id: json['id'] as int,
        fullName: json['fullName'] as String,
        branchId: json['branchId'] as int?,
      );
}
