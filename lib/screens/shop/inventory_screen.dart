import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/avatar_item.dart';
import '../../models/user_model.dart';
import '../../widgets/xp_coins_bar.dart';
import '../../widgets/universal_avatar_widget.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _user;
  List<AvatarItem> _ownedAvatars = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  void _loadInventory() {
    setState(() {
      _user = _firebaseService.currentUser;
      _ownedAvatars = _firebaseService.getShopAvatars().where((a) => a.isOwned).toList();
    });
  }

  void _openAvatarPreviewModal(AvatarItem avatar) {
    final bool isCurrentlyEquipped = _user?.activeAvatarLottie == avatar.lottiePath;

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

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

            Text(
              avatar.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRarityColor(avatar.rarity).withValues(alpha: 0.15),
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
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isCurrentlyEquipped
                    ? null
                    : () async {
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        await _firebaseService.updateActiveAvatar(avatar.lottiePath);
                        _loadInventory();
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${avatar.name} er nå valgt som din aktive avatar! ✨'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0446BC),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isCurrentlyEquipped ? 'Aktiv avatar' : 'Velg som aktiv avatar',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
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
          'Ditt inventar',
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
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _ownedAvatars.length,
                itemBuilder: (context, index) {
                  final avatar = _ownedAvatars[index];
                  final isEquipped = _user?.activeAvatarLottie == avatar.lottiePath;
                  final rarityColor = _getRarityColor(avatar.rarity);

                  return GestureDetector(
                    onTap: () => _openAvatarPreviewModal(avatar),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isEquipped ? const Color(0xFF0446BC) : rarityColor,
                          width: isEquipped ? 3 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                            isEquipped ? 'Aktiv avatar ✨' : 'Trykk for forhåndsvisning',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isEquipped ? const Color(0xFF0446BC) : const Color(0xFF64748B),
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
