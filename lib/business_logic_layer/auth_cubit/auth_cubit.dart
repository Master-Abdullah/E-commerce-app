import 'package:bloc/bloc.dart';
import 'package:e_commerce_app/Utilities/constants.dart';
import 'package:e_commerce_app/Utilities/enums.dart';
import 'package:e_commerce_app/data_layer/Models/user.dart';
import 'package:e_commerce_app/data_layer/Services/firebase_auth.dart';
import 'package:e_commerce_app/data_layer/repository/firestore_repo.dart';
import 'package:meta/meta.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  /// the uId isn't used in this class and it will be complex to inject it
  /// so we did tight coupling here and it become internal attribute
  final Repository repo = FirestoreRepo('0000');
  final AuthService authService;
  String email;
  String password;
  AuthFormType authFormType;
  AuthCubit(
      {required this.authService,
      this.email = '',
      this.password = '',
      this.authFormType = AuthFormType.login})
      : super(AuthInitial());

  ///copywith method should return object of the model if you will use it outside the calss
  ///but here we will use it inside the calss only to edit on some variables without create new object
  void copyWith({
    String? email,
    String? password,
    AuthFormType? authFormType,
  }) {
    this.email = email ?? this.email;
    this.password = password ?? this.password;
    this.authFormType = authFormType ?? this.authFormType;
  }

  ///update email and password stands for textControllers
  void updateEmail(String email) => copyWith(email: email);
  void updatePassword(String password) => copyWith(password: password);

  void toggleFormType() {
    final formType = authFormType == AuthFormType.login
        ? AuthFormType.register
        : AuthFormType.login;
    //بصفر الايميل والباسورد لما يغير من اللوجين
    copyWith(email: '', password: '', authFormType: formType);
    emit(FormTypeToggled(formType: formType));
  }

  Future<void> submit() async {
    emit(AuthLoading());
    try {
      if (authFormType == AuthFormType.login) {
        await authService.loginWithEmailAndPassword(email, password);
      } else {
        final user =
            await authService.signUpWithEmailAndPassword(email, password);
        await repo.setUserData(UserData(
          uId: user?.uid ?? kIdFromDartGenerator(),
          email: email,
        ));
      }
      print('Login/Register sucessss');
      emit(SuccessfulAuth());
    } catch (e) {
      print('authentication errorr :${e.toString()}');
      emit(FailureAuth(errorMsg: e.toString()));
    }
  }

  Future<void> logOut() async {
    try {
      await authService.logOut();
      emit(LogOut());
    } catch (e) {
      print('logout error: $e');
    }
  }
}