import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/avatar_item.dart';
import '../../models/user_model.dart';
import '../../widgets/xp_coins_bar.dart';
import '../../widgets/universal_avatar_widget.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _user;
  List<AvatarItem> _avatars = [];

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  void _loadShop() {
    setState(() {
      _user = _firebaseService.currentUser;
      _avatars = _firebaseService.getShopAvatars().where((a) => !a.isOwned).toList();
    });
  }

  // 1. Dedicated Detailed Preview Modal Sheet for Shop
  void _openAvatarPreviewModal(AvatarItem avatar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Zoomed-In Lottie Animation Playback Box (Transparent)
            SizedBox(
              width: 180,
              height: 180,
              child: UniversalAvatarWidget(
                avatarPath: avatar.lottiePath,
                size: 180,
                level: 50,
              ),
            ),
            const SizedBox(height: 16),

            // Avatar Name & Rarity Badge
            Text(
              avatar.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRarityColor(avatar.rarity).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                avatar.rarity.toUpperCase(),
                style: TextStyle(
                  color: _getRarityColor(avatar.rarity),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getAvatarDescription(avatar.id),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action Button: Kjøp for {price} Mynter (or Eies)
            if (avatar.isOwned)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '✅ Du eier allerede denne avataren',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmPurchaseDialog(avatar);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0446BC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: Text('Kjøp for ${avatar.priceCoins} Mynter'),
                ),
              ),
            const SizedBox(height: 12),

            // Secondary Button: Tilbake
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Tilbake', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Mandatory Purchase Confirmation Dialog ("Bekreftelse på kjøp")
  void _confirmPurchaseDialog(AvatarItem avatar) {
    if (_user != null && _user!.coins < avatar.priceCoins) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ikke nok Mynter! ⚠️'),
          content: Text('Du har ${_user!.coins} Mynter, men ${avatar.name} koster ${avatar.priceCoins} Mynter. Fullfør flere treningsøkter for å tjene Mynter!'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mottatt')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bekreft kjøp 💰'),
        content: Text('Vil du bekrefte kjøp av ${avatar.name} for ${avatar.priceCoins} Mynter?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Avbryt')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _firebaseService.purchaseAvatar(avatar);
              if (success) {
                _loadShop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Gratulerer! ${avatar.name} er nå i ditt inventar!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0446BC)),
            child: const Text('Bekreft kjøp'),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'legendarisk':
        return AppTheme.goldCoins;
      case 'sjelden':
        return AppTheme.purpleXP;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _getAvatarDescription(String id) {
    switch (id) {
      case 'avatar_runner':
        return 'Standard sprekk løper som alltid er klar for en ny økt!';
      case 'avatar_hero':
        return 'En eksklusiv superhelt-avatar for aktive ungdommer som oppnår store mål.';
      case 'avatar_dragon':
        return 'En legendarisk gull-drage som viser at du er en sann mester i treningen!';
      default:
        return 'En unik 2D Lottie-avatar for din profil.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Avatar-butikk',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_user != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: XpCoinsBar(user: _user!),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _avatars.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('🛒', style: TextStyle(fontSize: 60)),
                          SizedBox(height: 12),
                          Text(
                            'Ingen flere avatarer i butikken!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Du har allerede Techno Carl 🥊 i ditt inventar.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _avatars.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatars[index];
                        final rarityColor = _getRarityColor(avatar.rarity);

                        return GestureDetector(
                          onTap: () => _openAvatarPreviewModal(avatar),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: rarityColor, width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                 SizedBox(
                                   width: 90,
                                   height: 90,
                                   child: UniversalAvatarWidget(
                                     avatarPath: avatar.lottiePath,
                                     size: 90,
                                     level: 50,
                                   ),
                                 ),
                                const SizedBox(height: 10),
                                Text(
                                  avatar.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  avatar.isOwned ? 'Eies ✅' : '${avatar.priceCoins} Mynter 💰',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: avatar.isOwned ? Colors.green : const Color(0xFF0446BC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
