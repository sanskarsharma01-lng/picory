import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/photo_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/photo_grid.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final albumPhotos = PhotoModel.getAlbumPhotos();

    return albumPhotos.isEmpty
        ? Center(
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
                  'No photos in album',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select photos from groups to see them here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${albumPhotos.length} Selected Photos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.grid_view),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.view_list),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PhotoGrid(
                  photos: albumPhotos,
                  onPhotoTap: (photo, index) async {
                    await Navigator.pushNamed(
                      context,
                      AppConstants.photoViewRoute,
                      arguments: {
                        'photo': photo,
                        'photos': albumPhotos,
                        'initialIndex': index,
                      },
                    );
                    // Refresh the screen when coming back from view screen
                    setState(() {});
                  },
                ),
              ),
            ],
          );
  }
}