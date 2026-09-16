import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/auth/view/pages/signup_page.dart';
import 'package:client/features/home/repositories/home_local_repository.dart';
import 'package:client/features/home/view/pages/upload_song_page.dart';
import 'package:client/features/home/viewmodel/home_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WRAPPED IN SCAFFOLD TO ADD APPBAR FOR LOGOUT
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            onPressed: () async {
              // 1. Delete token from storage
              await ref.read(authLocalRepositoryProvider).removeToken();
              
              // 2. Clear old user's recently played songs from Hive using the repo (No await needed)
              ref.read(homeLocalRepositoryProvider).clearBox();
              
              // 3. Stop the music and clear the active song
              ref.read(currentSongNotifierProvider.notifier).clear();
              
              // 4. Safely reset global user state to null
              ref.read(currentUserNotifierProvider.notifier).addUser(null);
              
              // 5. Send back to Auth screen
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SignupPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: ref
          .watch(getFavSongsProvider)
          .when(
            data: (data) {
              return ListView.builder(
                itemCount: data.length + 1,
                itemBuilder: (context, index) {
                  if (index == data.length) {
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UploadSongPage(),
                          ),
                        );
                      },
                      leading: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Pallete.backgroundColor,
                        child: Icon(CupertinoIcons.plus),
                      ),
                      title: const Text(
                        'Upload New Song',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  final song = data[index];
                  return ListTile(
                    onTap: () {
                      ref
                          .read(currentSongNotifierProvider.notifier)
                          .updateSong(song);
                    },
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(song.thumbnail_url),
                      radius: 35,
                      backgroundColor: Pallete.backgroundColor,
                    ),
                    title: Text(
                      song.song_name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      song.artist,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              );
            },
            error: (error, st) {
              return Center(child: Text(error.toString()));
            },
            loading: () => const Loader(),
          ),
    );
  }
}
