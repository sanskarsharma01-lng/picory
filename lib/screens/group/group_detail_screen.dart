import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/group_model.dart';
import '../../models/photo_model.dart';
import '../../providers/language_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/photo_grid.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PhotoModel> _allPhotos = [];
  List<PhotoModel> _myPhotos = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final token = profileProvider.token;

    try {
      final response = await http.get(
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/group/${widget.group.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> photosData = responseData['data']['photos']['photos'];
          setState(() {
            _allPhotos = photosData.map((p) => PhotoModel.fromMap(p)).toList();
            // Filtering logic for "My Photos" would go here if API supports it
            // For now, we'll use a dummy filter or keep it empty if not applicable
            _myPhotos = _allPhotos.where((p) => p.isMyPhoto).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = responseData['message'] ?? 'Failed to load details';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load details: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.group.eventTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.group.thumbnailUrl != null)
                      Image.network(
                        widget.group.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.grey[300]);
                        },
                      )
                    else
                      Container(color: Colors.grey[300]),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: [
                    Tab(text: langProvider.translate('my_photos')),
                    Tab(text: langProvider.translate('all_photos')),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
            ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPhotoTab(_myPhotos),
                  _buildPhotoTab(_allPhotos),
                ],
              ),
      ),
    );
  }

  Widget _buildPhotoTab(List<PhotoModel> photos) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No photos yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return PhotoGrid(
      photos: photos,
      onPhotoTap: (photo, index) {
        Navigator.pushNamed(
          context,
          AppConstants.photoViewRoute,
          arguments: {
            'photo': photo,
            'photos': photos,
            'initialIndex': index,
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}