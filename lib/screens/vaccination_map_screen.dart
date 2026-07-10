import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/map/hospital_finder.dart';

/// 근처 접종 가능 병원/의원 지도(OSM 데이터 + CARTO Voyager 타일, 키 불필요).
class VaccinationMapScreen extends StatefulWidget {
  const VaccinationMapScreen({super.key});

  @override
  State<VaccinationMapScreen> createState() => _VaccinationMapScreenState();
}

class _VaccinationMapScreenState extends State<VaccinationMapScreen> {
  final HospitalFinder _finder = HospitalFinder();
  final MapController _mapController = MapController();

  LatLng? _center;
  List<Place> _places = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final center = await _finder.currentLocation();
      final places = await _finder.searchNearby(center);
      if (!mounted) return;
      setState(() {
        _center = center;
        _places = places;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '병원 정보를 불러오지 못했어요.';
      });
    }
  }

  void _focus(Place p) {
    _mapController.move(p.latLng, 16);
  }

  @override
  Widget build(BuildContext context) {
    final center = _center;
    return Scaffold(
      appBar: AppBar(
        title: const Text('근처 병원'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : center == null
          ? Center(child: Text(_error ?? '위치를 확인할 수 없어요.'))
          : Column(
              children: [
                SizedBox(
                  height: 300,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(initialCenter: center, initialZoom: 14),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.hyunsu.hanppyeom',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 36,
                            height: 36,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                            ),
                          ),
                          for (final p in _places)
                            Marker(
                              point: p.latLng,
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.local_hospital,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution('OpenStreetMap contributors'),
                          TextSourceAttribution('CARTO'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildList(center)),
              ],
            ),
    );
  }

  Widget _buildList(LatLng center) {
    if (_places.isEmpty) {
      return const Center(child: Text('주변에서 병원을 찾지 못했어요.'));
    }
    const distance = Distance();
    final sorted = [..._places]
      ..sort(
        (a, b) => distance
            .as(LengthUnit.Meter, center, a.latLng)
            .compareTo(distance.as(LengthUnit.Meter, center, b.latLng)),
      );
    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = sorted[i];
        final meters = distance.as(LengthUnit.Meter, center, p.latLng).round();
        final label = meters >= 1000
            ? '${(meters / 1000).toStringAsFixed(1)}km'
            : '${meters}m';
        return ListTile(
          leading: const Icon(Icons.local_hospital, color: Colors.red),
          title: Text(p.name),
          trailing: Text(label),
          onTap: () => _focus(p),
        );
      },
    );
  }
}
