import 'package:flutter/material.dart';
import 'package:weezemaster/core/models/artist.dart';
import 'package:weezemaster/core/services/api_services.dart';
import 'package:weezemaster/components/concert_list_item.dart';

class ArtistScreen extends StatefulWidget {
  final String id;

  const ArtistScreen({super.key, required this.id});

  @override
  _ArtistScreenState createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Artist? artist;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchArtistAndConcerts();
  }

  Future<void> _fetchArtistAndConcerts() async {
    artist = await ApiServices.getArtist(widget.id);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(artist?.name ?? 'Loading...'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Concerts'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: artist == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConcertsTab(),
                _buildChatTab(),
              ],
            ),
    );
  }

  Widget _buildConcertsTab() {
    return ListView.builder(
      itemCount: artist!.concerts.length,
      itemBuilder: (context, index) {
        final concert = artist!.concerts[index];
        return ConcertListItem(concert: concert, showArtistName: false);
      },
    );
  }

  Widget _buildChatTab() {
    return const Center(
      child: Text('Chat feature'),
    );
  }
}