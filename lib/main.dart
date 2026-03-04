import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

//  Aqui estamos criando a arquitetura do nosso aplicativo
class MyApp extends StatelessWidget {
  
  const MyApp({super.key}); // esta constante permite que o Flutter otimize a reconstrução do widget e a (key) auxilia o framework a identificar widgets na árvore.

  // personalizando o construtor
  @override
  Widget build(BuildContext context) { // O BuildContext representa a posição deste widget na árvore de widgets,
                                      // permitindo acesso a temas, providers e widgets ancestrais.

    // aqui criamos um provider que servira como notificador de nosso sistema, sempre houver mudança (ação) do usuário, ele deverá notificar os demais widgets que estão conectados.
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

// após criar o ponteiro para notificar, devemos criar um (ponteiro?) para salvar o estado de nosso sistema, podendo assim fazer a comparação
class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  // Entendi que aqui criamos uma variavel para armazenar histórico das palavras que foram geradas.
  var history = <WordPair>[];

  // Variável que armazena uma referência para o estado interno do AnimatedList,
  // permitindo que o estado global dispare animações de forma controlada.
  GlobalKey<AnimatedListState>? historyListKey;

  // Observação: este método concentra mais de uma responsabilidade.
  // Em projetos maiores, seria interessante separar essas ações.
  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState;
    animatedList?.insertItem(0);

    current = WordPair.random();
    notifyListeners();
  }

  //lista de palavras favoritadas
  var favorites = <WordPair>[];

  // interação de favoritar alguma palavra
  void toggleFavorite( [WordPair? pair] ) { // aqui passamos um único pair opcional, no caso, a palavra que estiver sob o mouse. No caso do celular, a palavra em que clicarmos será o pair.
    pair = pair ?? current; // estamos verificando se é o pair sendo usado do momento

    // logica para favoritar aquele par de palavras
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

// criando a interface da página principal, 

// O StatefulWidget é imutável, mas delega seu estado mutável para a classe State,
// permitindo controle do ciclo de vida e atualização da interface.

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0; // essa variável quem define em qual página estamos, se é na home ou se é na lista de palavras
// setando a cor do tema.
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch(selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // anima a transiçao das páginas, no caso, ir da página home para favorites e vice-versa.
    var mainArea = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    // aqui ele está retornando a tela do app, layout responsivo
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {

          // bloco totalmente modificado:
          // se o tamanho da tela do dispositvo por menor que 450 pixeis:
          if (constraints.maxWidth < 450){
            return Column(
              children: [
                Expanded(child: mainArea,),
                SafeArea(
                  child: BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.favorite),
                        label: 'Favorites',
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                    
                  ),
                )
              ],
            );
          // se for maior que 450:
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home), 
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite),
                        label: Text('Favorites'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
                Expanded(child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}

// uma classe parapágina do gerador de palavras
class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    // este bloco pode ser escrito assim:
    IconData icon = appState.favorites.contains(pair)
        ? Icons.favorite
        : Icons.favorite_border;

    // ou escrito assim:

    // IconData icon;
    // if (appState.favorites.contains(pair)) {
    //   icon = Icons.favorite;
    // } else {
    //   icon = Icons.favorite_border;
    // }

    // interface de onde ficará posicionado o gerador de plavras.
    return Center(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),

          const SizedBox(height: 10),

          // CARD PRINCIPAL
          BigCard(pair: pair),

          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: const Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 20,)
        ],
      ),
    );
  }
}

// classe para a página de palavras favoritadas
class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    if (appState.favorites.isEmpty) {
      return const Center(
        child: Text("No favorites yet."),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "You have ${appState.favorites.length} favorites:",
          style: theme.textTheme.titleMedium,
        ), 
        const SizedBox(height: 10),

        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(
              Icons.favorite, 
              color: theme.colorScheme.primary
            ),
            title: Text(pair.asLowerCase),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                appState.removeFavorite(pair);
              },
            ),
          ),
      ],
    );
  }
}

// uma classe de "apoio", para definirmos o visual para o card, onde a palavra estará dentro dele.
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Text(
          pair.asLowerCase, 
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({super.key});

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView>{
  final _key = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();

    // 🔗 Conexão entre UI e estado global
    appState.historyListKey = _key;

    return AnimatedList(
      key: _key,
      reverse: true,
      padding: const EdgeInsets.only(top: 20),
      initialItemCount: appState.history.length,
      itemBuilder: (context, index, animation) {
        final pair = appState.history[index];

        return SizeTransition(
          sizeFactor: animation,
          child: ListTile(
            title: Text(pair.asLowerCase),
            trailing: IconButton(
              icon: Icon(
                appState.favorites.contains(pair)
                  ? Icons.favorite : Icons.favorite_border,
                size: 18,
              ),
              onPressed: () {
                appState.toggleFavorite(pair);
              },
            ),
          )
        );
      },
    );
  }
}