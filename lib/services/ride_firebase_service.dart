import 'package:firebase_database/firebase_database.dart';

class RideFirebaseService {
  // Hàm trả về Stream để UI lắng nghe thay đổi
  Stream<DatabaseEvent> getRideStream(String rideId) {
    // Trỏ đúng vào node: rides/{rideId}
    return FirebaseDatabase.instance.ref('rides/$rideId').onValue;
  }
}