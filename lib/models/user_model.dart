class User {
  final String email;
  final String password;
  final String name;

  User({required this.email, required this.password, required this.name});

  Map<String, dynamic> toMap() => {
    'email': email,
    'password': password,
    'name': name,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    email: map['email'],
    password: map['password'],
    name: map['name'],
  );
}
