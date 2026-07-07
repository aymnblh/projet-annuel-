import 'package:share_plus/share_plus.dart';
import '../models/product.dart';

class ShareService {
  
  static void shareProduct(Product product) {
    // Construction du message intelligent
    final String deepLink = "oneclick://product/${product.id}";
    final String message = 
      "Découvrez ${product.title} à ${product.price.toStringAsFixed(0)} DA sur OneClick !\n\n"
      "Voir l'annonce ici : $deepLink";

    Share.share(message, subject: "Regarde ça sur OneClick !");
  }
}
