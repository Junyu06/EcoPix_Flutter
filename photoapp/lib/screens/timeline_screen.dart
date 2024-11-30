import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photoapp/screens/photo_detail.dart';
import 'package:photoapp/widgets/unsplash_api.dart'; // Import your server connection

class TimelineScreen extends StatefulWidget {
  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<dynamic> _photos = [];
  int _pageNumber = 1;//initial the page number
  final int _per_page = 20;//number of photo per page
  bool _isLoading = false;
  ScrollController _scrollController = ScrollController();
  ServerConnection API = ServerConnection();
  String _navigationBarTitle = 'Timeline';

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
    _scrollController.addListener(_scrollListner);
  }

  Future<void> _fetchPhotos() async {
    if (_isLoading) return;// aviod mutiple calls when already loading

    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> newPhotos = await ServerConnection().fetchPhotos(_pageNumber, _per_page);
      setState(() {
        _photos.addAll(newPhotos);
        _pageNumber++;
      });
    } catch (error) {
      print('Error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollListner(){
    if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent && !_isLoading){
      _fetchPhotos();//load more photos when reaching the end
    }

    //navigation bar title based on the first visible photo's date
    if (_photos.isNotEmpty && _scrollController.hasClients){
      double offset = _scrollController.offset;
      int visibleIndex = (offset / 150).floor(); //estimate which photo is visible(150 is the height of each photo)

      if (visibleIndex >= 0 && visibleIndex < _photos.length){
        String date = _photos[visibleIndex]['created_at'];
        String formattedDate = date.split('T')[0];//get the date in YYY-MM-DD
        setState(() {
          _navigationBarTitle = formattedDate;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_navigationBarTitle),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildPhotoGrid(),
            ),
            if (_isLoading)
              CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(){
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index){
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context, 
              CupertinoPageRoute(
                fullscreenDialog: true,
                //rootNavigator: true,
                builder: (context) => new PhotoDetailScreen(
                  photos: _photos, 
                  intialIndex: index,
                ),
              ),
            );
          },
          child: CachedNetworkImage(
            imageUrl: _photos[index]['urls']['thumb'], 
            fit:BoxFit.cover,
            //borderRadius: BorderRadius.circular(8.0),
            placeholder: (context, url) => CupertinoActivityIndicator(),
            errorWidget: (context, url, error) => Icon(CupertinoIcons.exclamationmark_triangle),
          ),
        );
      },
    );
  }

  @override
  void dispose(){
    _scrollController.dispose();//aviod memory leak
    super.dispose();
  }
}
