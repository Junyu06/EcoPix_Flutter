import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

class PhotoDetailScreen extends StatefulWidget{
  final List<dynamic> photos;//list of photo for pass in
  final int intialIndex; //index of the photo to display first

  const PhotoDetailScreen(
    {
      required this.photos, required this.intialIndex
    }
  );

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen>{
  late PageController _pageController;
  int currentIndex = 0;
  bool _showTooBar = true;

  @override
  void initState(){
    super.initState();
    _pageController = PageController(initialPage: widget.intialIndex);
    //_preloadImages(currentIndex);
    currentIndex = widget.intialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages(currentIndex);
    });
  }

  void _preloadImages(int index){
    for (int i = index -3; i<= index+3; i++){
      if (i>=0 && i< widget.photos.length){
        precacheImage(NetworkImage(widget.photos[i]['urls']['full']), context);
      }
    }
  }

  void _toggleTooBar(){
    setState(() {
      _showTooBar =!_showTooBar;//toggle toolbar visibility
    });
  }

  Future<void> _sharePhoto() async{//change later for save photo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shared_photo', widget.photos[currentIndex]['urls']['full']);
    print('Photo Shared: ${widget.photos[currentIndex]['urls']['full']}');
  }

  void _setRating(int stars){
    //change it later for star rating logic
    print('Rated $stars stars for photo: ${widget.photos[currentIndex]['urls']['full']}');
  }

  @override
Widget build(BuildContext context) {
  final photoDate = widget.photos[currentIndex]; // Get current photo data
  return CupertinoPageScaffold(
    backgroundColor: CupertinoColors.black, // Ensure the background is black
    navigationBar: _showTooBar ? CupertinoNavigationBar(
      backgroundColor: CupertinoColors.black.withOpacity(0.5), // Semi-transparent background for the nav bar
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Icon(CupertinoIcons.clear, color: CupertinoColors.white), // White close icon
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      middle: Text(
        'Photo ${currentIndex + 1}', 
        style: TextStyle(color: CupertinoColors.white), // White text
      ),
    ) : null,
    child: Stack(
      children: [
        GestureDetector(
          onTap: () {
            // Show toolbar when tapped
            _toggleTooBar();
          },
          onVerticalDragUpdate: (details) {
            int sensitivity = 8;
            if (details.delta.dy > sensitivity) {
              Navigator.pop(context);
            } else if (details.delta.dy < -sensitivity) {
              Navigator.pop(context);
            }
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
              _preloadImages(index);
            },
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  child: Image.network(
                    widget.photos[index]['urls']['full'], // Use photo URL from the current photo
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CupertinoActivityIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          CupertinoIcons.exclamationmark_circle,
                          color: CupertinoColors.systemRed,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        // Conditionally show the toolbar at the bottom
        if (_showTooBar == true)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: 
            Container(
              color: CupertinoColors.black.withOpacity(0.5),
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _sharePhoto();
                    },
                    child: Icon(CupertinoIcons.share, color: CupertinoColors.white),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showInfo();
                    },
                    child: Icon(CupertinoIcons.info, color: CupertinoColors.white),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showStarRating();
                    },
                    child: Icon(CupertinoIcons.star, color: CupertinoColors.white),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _deletePhoto();
                    },
                    child: Icon(CupertinoIcons.delete, color: CupertinoColors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

void _showInfo() {
  Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (BuildContext context) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text('Photo Metadata'),
            /*
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.clear, color: CupertinoColors.systemRed),
              onPressed: () => Navigator.of(context).pop(),
            ),
            */
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Name: ${widget.photos[currentIndex]['slug']}',
                  style: TextStyle(fontSize: 18, color: CupertinoColors.black),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}



/*
  Widget _buildToolbar(){
    return CupertinoActionSheet(
      actions: [
        CupertinoButton(
          child: Icon(CupertinoIcons.share, size: 30, color: CupertinoColors.white,),
          onPressed: _sharePhoto,
        ),
        CupertinoButton(
          child: Icon(CupertinoIcons.info, size:30, color: CupertinoColors.white,), 
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (BuildContext context){
                return CupertinoAlertDialog(
                  title: Text('Photo MetaData'),
                  content: Text('Details: ${widget.photos[currentIndex]}'),
                  actions: [
                    CupertinoDialogAction(
                      child: Icon(CupertinoIcons.clear, size: 30, color: CupertinoColors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          },
        ),
        CupertinoButton(
          child: Icon(CupertinoIcons.star, size: 30, color: CupertinoColors.white), 
          onPressed: (){
            _showStarRating();
          },
        ),
        CupertinoButton(
          child: Icon(CupertinoIcons.delete, size: 30, color: CupertinoColors.black),
          onPressed: () {
            _deletePhoto();
          },
        ),
      ],
    );
  }

*/
  void _deletePhoto(){//chnage it later
    //nothing
  }

  void _showStarRating() {//change it later
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text('Rate this photo'),
          actions: List.generate(5, (index) {
            return CupertinoButton(
              child: Text('${index + 1} Stars'),
              onPressed: () {
                _setRating(index + 1);
                Navigator.of(context).pop();
              },
            );
          }),
        );
      },
    );
  }
}
