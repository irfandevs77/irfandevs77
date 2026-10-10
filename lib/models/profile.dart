class Profile {
  const Profile({
    required this.name,
    required this.username,
    required this.pronouns,
    required this.bio,
    required this.location,
    required this.email,
    required this.website,
    required this.joined,
    this.about = '',
    this.avatarUrl = '',
    this.resumeUrl = '',
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    name: _string(map['name'], 'Irfan'),
    username: _string(map['username'], 'irfandevs77'),
    pronouns: _string(map['pronouns'], 'he/him'),
    bio: _string(
      map['bio'],
      'Developer Enthusiast | Developer | AI & Computer Science | Student',
    ),
    location: _string(map['location'], 'India'),
    email: _string(map['email'], 'irfandevs77@gmail.com'),
    website: _string(map['website'], 'instagram.com/irfandevs77'),
    joined: _string(map['joined'], 'Joined last month'),
    about: _string(map['about'], ''),
    avatarUrl: _string(map['avatarUrl'], ''),
    resumeUrl: _string(map['resumeUrl'], ''),
  );

  factory Profile.defaults() => Profile.fromMap(const {});

  final String name;
  final String username;
  final String pronouns;
  final String bio;
  final String location;
  final String email;
  final String website;
  final String joined;
  final String about;
  final String avatarUrl;
  final String resumeUrl;

  Map<String, dynamic> toMap() => {
    'name': name,
    'username': username,
    'pronouns': pronouns,
    'bio': bio,
    'location': location,
    'email': email,
    'website': website,
    'joined': joined,
    'about': about,
    'avatarUrl': avatarUrl,
    'resumeUrl': resumeUrl,
  };

  static String _string(Object? value, String fallback) =>
      value is String ? value : fallback;
}
