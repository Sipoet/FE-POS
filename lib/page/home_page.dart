import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 680.0) {
          return _desktopHome();
        }
        return _mobileHome();
      },
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
      const Text('Desktop',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      IconButton(
          onPressed: () {
            // print('clicked');
          },
          icon: const Icon(Icons.receipt))
    ];
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Column(children: menubar),
          const Text('Desktop 2', style: TextStyle(fontSize: 20))
        ],
      ),
    );
  }

  Widget _mobileHome() {
    return const Padding(
      padding: EdgeInsets.all(10),
      child: Text('Mobile', style: TextStyle(fontSize: 20)),
    );
  }
}
