// import 'package:flutter/material.dart';

// class GeneratorPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     var appState = context.watch<SessionState>();
//     var pair = appState.current;

//     IconData icon;
//     if (appState.favorites.contains(pair)) {
//       icon = Icons.favorite;
//     } else {
//       icon = Icons.favorite_border;
//     }

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           BigCard(pair: pair),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: () {
//                   appState.toggleFavorite();
//                 },
//                 icon: Icon(icon),
//                 label: const Text('Like'),
//               ),
//               const SizedBox(width: 10),
//               ElevatedButton(
//                 onPressed: () {
//                   appState.getNext();
//                 },
//                 child: const Text('Next'),
//               ),
//               const SizedBox(width: 10),
//               ElevatedButton(
//                 onPressed: () {
//                   appState.resetFavorite();
//                 },
//                 child: const Text('reset'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class BigCard extends StatelessWidget {
//   const BigCard({
//     super.key,
//     required this.pair,
//   });

//   final WordPair pair;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final style = theme.textTheme.displayMedium!
//         .copyWith(color: theme.colorScheme.onPrimary);
//     return Card(
//       color: theme.colorScheme.primary,
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Text(pair.asLowerCase,
//             style: style, semanticsLabel: "${pair.first} ${pair.second}"),
//       ),
//     );
//   }
// }


