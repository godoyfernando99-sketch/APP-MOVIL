class AnimalCategory {
  static const String home = 'home';
  static const String farm = 'farm';
}

class Animal {
  const Animal({required this.id, required this.name, required this.category, required this.assetImage});
  final String id;
  final String name;
  final String category;
  final String assetImage;
}

class AnimalsCatalog {
  static const animals = <Animal>[
    // Animales de Casa
    Animal(id: 'dog', name: 'Perro', category: AnimalCategory.home, assetImage: 'assets/images/Dog_null_1769386481579.jpg'),
    Animal(id: 'cat', name: 'Gato', category: AnimalCategory.home, assetImage: 'assets/images/Cat_null_1769386482564.jpg'),
    Animal(id: 'frog', name: 'Rana', category: AnimalCategory.home, assetImage: 'assets/images/Frog_null_1769386483382.jpg'),
    Animal(id: 'parrot', name: 'Loro', category: AnimalCategory.home, assetImage: 'assets/images/Parrot_null_1769386484424.jpg'),
    Animal(id: 'turtle', name: 'Tortuga', category: AnimalCategory.home, assetImage: 'assets/images/Turtle_null_1769386485330.jpg'),
    Animal(id: 'hamster', name: 'Hamster', category: AnimalCategory.home, assetImage: 'assets/images/Hamster_null_1769386486660.jpg'),
    Animal(id: 'fish', name: 'Pez', category: AnimalCategory.home, assetImage: 'assets/images/Fish_aquarium_null_1769386487497.jpg'),
    Animal(id: 'lizard', name: 'Lagartija', category: AnimalCategory.home, assetImage: 'assets/images/Lizard_null_1769386488785.jpg'),
    Animal(id: 'ferret', name: 'Hurón', category: AnimalCategory.home, assetImage: 'assets/images/Ferret_null_1769386489474.jpg'),
    
    // Animales de Granja
    Animal(id: 'horse', name: 'Caballo', category: AnimalCategory.farm, assetImage: 'assets/images/Horse_null_1769386490441.jpg'),
    Animal(id: 'goat', name: 'Cabra', category: AnimalCategory.farm, assetImage: 'assets/images/Goat_null_1769386491813.jpg'),
    Animal(id: 'billy_goat', name: 'Chivo', category: AnimalCategory.farm, assetImage: 'assets/images/Billy_goat_null_1769386492855.jpg'),
    Animal(id: 'mare', name: 'Yegua', category: AnimalCategory.farm, assetImage: 'assets/images/Mare_horse_null_1769386493855.jpg'),
    Animal(id: 'bull', name: 'Toro', category: AnimalCategory.farm, assetImage: 'assets/images/bull_realistic_photo_brown_1769096585312.jpg'),
    Animal(id: 'mule_f', name: 'Mula', category: AnimalCategory.farm, assetImage: 'assets/images/mule_realistic_photo_brown_1769096586387.jpg'),
    Animal(id: 'mule_m', name: 'Mulo', category: AnimalCategory.farm, assetImage: 'assets/images/donkey_realistic_photo_gray_1769096592887.jpg'),
    Animal(id: 'rooster', name: 'Gallo', category: AnimalCategory.farm, assetImage: 'assets/images/Rooster_null_1769386498199.jpg'),
    Animal(id: 'hen', name: 'Gallina', category: AnimalCategory.farm, assetImage: 'assets/images/hen_realistic_photo_brown_1769096588014.jpg'),
    Animal(id: 'pig', name: 'Cerdo', category: AnimalCategory.farm, assetImage: 'assets/images/Pig_null_1769386500051.jpg'),
    Animal(id: 'sheep', name: 'Oveja', category: AnimalCategory.farm, assetImage: 'assets/images/Sheep_null_1769386501647.jpg'),
    Animal(id: 'duck', name: 'Pato', category: AnimalCategory.farm, assetImage: 'assets/images/Duck_null_1769386502845.jpg'),
    Animal(id: 'turkey', name: 'Pavo', category: AnimalCategory.farm, assetImage: 'assets/images/Turkey_null_1769386503581.jpg'),
    Animal(id: 'peacock', name: 'Pavo real', category: AnimalCategory.farm, assetImage: 'assets/images/Peacock_null_1769386504456.jpg'),
    Animal(id: 'burro', name: 'Burro', category: AnimalCategory.farm, assetImage: 'assets/images/female_mule_realistic_photo_brown_1769097010770.jpg'),
    Animal(id: 'cow', name: 'Vaca', category: AnimalCategory.farm, assetImage: 'assets/images/ai_generated_1769158692690.jpg'),
  ];

  static Animal byId(String id) => animals.firstWhere((a) => a.id == id);
}
