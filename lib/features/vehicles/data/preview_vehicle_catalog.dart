/// Preview catalogue of car brands and their models.
///
/// Foundation placeholder: the real catalogue belongs to the backend; the
/// driver picks from it instead of typing a brand by hand.
const previewVehicleCatalog = <String, List<String>>{
  'Abarth': ['124 Spider', '500', '595', '695'],
  'AC Cars': ['Ace', 'Aceca', 'Cobra'],
  'Acura': ['ILX', 'MDX', 'RDX', 'TLX', 'ZDX'],
  'Alfa Romeo': ['147', '156', 'Giulia', 'Giulietta', 'Stelvio'],
  'Alpina': ['B3', 'B5', 'B7', 'XD3'],
  'Ariel': ['Atom', 'Nomad'],
  'Aston Martin': ['DB9', 'DB11', 'DBX', 'Vantage'],
  'Audi': ['A3', 'A4', 'A6', 'A8', 'Q3', 'Q5', 'Q7', 'Q8'],
  'BMW': ['1 series', '3 series', '5 series', '7 series', 'X1', 'X3', 'X5'],
  'Bugatti': ['Chiron', 'Veyron'],
  'Chery': ['Tiggo 4', 'Tiggo 7 Pro', 'Tiggo 8 Pro'],
  'Ford': ['Focus', 'Kuga', 'Mondeo', 'Transit'],
  'Geely': ['Atlas', 'Coolray', 'Monjaro', 'Tugella'],
  'Haval': ['Dargo', 'F7', 'Jolion'],
  'Hyundai': ['Creta', 'Elantra', 'Solaris', 'Sonata', 'Tucson'],
  'Infiniti': [
    'EX',
    'FX',
    'G',
    'I',
    'J',
    'JX',
    'M',
    'Q30',
    'Q40',
    'Q45',
    'Q50',
    'Q60',
    'Q70',
    'QX50',
    'QX60',
    'QX80',
  ],
  'Isuzu': ['D-Max', 'MU-X', 'NQR'],
  'Iveco': ['Daily', 'Eurocargo', 'Stralis'],
  'KIA': ['Ceed', 'Optima', 'Rio', 'Seltos', 'Sportage'],
  'LADA': ['Granta', 'Largus', 'Niva', 'Vesta', 'XRAY'],
  'Mercedes-Benz': ['A-class', 'C-class', 'E-class', 'S-class', 'Sprinter'],
  'Nissan': ['Almera', 'Qashqai', 'X-Trail'],
  'Renault': ['Duster', 'Logan', 'Sandero'],
  'Skoda': ['Fabia', 'Kodiaq', 'Octavia', 'Rapid'],
  'Toyota': ['Camry', 'Corolla', 'Land Cruiser', 'RAV4'],
  'Volkswagen': ['Caravelle', 'Passat', 'Polo', 'Tiguan', 'Transporter'],
};

/// Brands in the order the picker lists them.
List<String> get previewVehicleBrands =>
    previewVehicleCatalog.keys.toList(growable: false);

/// Models of [brand]; empty when the brand is not in the catalogue.
List<String> previewVehicleModels(String brand) =>
    previewVehicleCatalog[brand] ?? const [];
