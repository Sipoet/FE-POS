import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 800) {
            return _desktopHome();
          }
          return _mobileHome();
        },
      ),
    );

    // return Scaffold(
    //     appBar: AppBar(
    //       title: Text('title app'),
    //       centerTitle: true,
    //       backgroundColor: Colors.amber[300],
    //     ),
    //     body: Center(child: Image.asset('assets/logo-allegra.jpg')
    //         // child: Text('body text fuyoh',
    //         //     style: TextStyle(
    //         //         fontSize: 22,
    //         //         fontWeight: FontWeight.bold,
    //         //         letterSpacing: 2.0,
    //         //         fontFamily: 'indieFlower')),
    //         ),
    //     floatingActionButton: FloatingActionButton(
    //       child: Text('click'),
    //       onPressed: () {},
    //       backgroundColor: Colors.amber[400],
    //     ));
  }

  Widget _desktopHome() {
    List<Widget> menubar = [
      Text('report',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      IconButton(
          onPressed: () {
            print('clicked');
          },
          icon: const Icon(Icons.receipt))
    ];
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Column(children: menubar),
          Text('Desktop 2', style: TextStyle(fontSize: 20))
        ],
      ),
    );
  }

  Widget _mobileHome() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text('Mobile', style: TextStyle(fontSize: 20)),
    );
  }
}
