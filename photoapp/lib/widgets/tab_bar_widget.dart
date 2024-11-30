import 'package:flutter/cupertino.dart';
import 'package:photoapp/screens/screens.dart';

class TabBarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.time),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.folder),
            label: 'Folder',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.photo),
            label: 'Album',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.info),
            label: 'Metadata',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (context) {
              return TimelineScreen(); // Timeline screen as the first tab
            });
          case 1:
            return CupertinoTabView(builder: (context) {
              return FolderScreen(); // Folder tab
            });
          case 2:
            return CupertinoTabView(builder: (context) {
              return AlbumScreen(); // Album tab
            });
          case 3:
            return CupertinoTabView(builder: (context) {
              return MetadataScreen(); // Metadata tab
            });
          default:
            return CupertinoTabView(builder: (context) {
              return Center(child: Text('Unknown Tab'));
            });
        }
      },
    );
  }
}
