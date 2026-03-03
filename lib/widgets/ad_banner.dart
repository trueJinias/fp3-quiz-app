import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';

class AdBanner extends StatefulWidget {
  final AdSize size;
  const AdBanner({super.key, this.size = AdSize.banner});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AdSize? _adSize;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted && AdHelper.isSupported) {
      _loadStarted = true;
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final adUnitId = AdHelper.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    AdSize adSize = widget.size;
    // Use adaptive banner for the default banner to fill screen width
    if (widget.size == AdSize.banner) {
      final screenWidth = MediaQuery.of(context).size.width.truncate();
      final adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(screenWidth);
      if (adaptiveSize != null && mounted) {
        adSize = adaptiveSize;
      }
    }

    if (!mounted) return;

    setState(() {
      _adSize = adSize;
    });

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Ad failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: double.infinity,
        height: (_adSize ?? _bannerAd!.size).height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return Container(
      height: (_adSize ?? widget.size).height.toDouble(),
      width: double.infinity,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Text('Ad Space (Loading/Dev)', style: TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }
}
