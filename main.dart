import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('notes');
  runApp(const MyApp());
}

/* -------------------- THEMES -------------------- */

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.deepPurple,
  brightness: Brightness.light,
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: Colors.deepPurple,
  brightness: Brightness.dark,
);

/* -------------------- APP -------------------- */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotesProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const NotesPage(),
      ),
    );
  }
}

/* -------------------- PROVIDER -------------------- */

class NotesProvider extends ChangeNotifier {
  final Box box = Hive.box('notes');

  List<Map> get notes =>
      box.values.map((e) => Map<String, dynamic>.from(e)).toList();

  List keys() => box.keys.toList();

  void add(String title, String content) {
    box.put(
      const Uuid().v4(),
      {
        'title': title,
        'content': content,
        'time': DateTime.now().toString(),
      },
    );
    notifyListeners();
  }

  void update(String key, String title, String content) {
    box.put(
      key,
      {
        'title': title,
        'content': content,
        'time': DateTime.now().toString(),
      },
    );
    notifyListeners();
  }

  void remove(String key) {
    box.delete(key);
    notifyListeners();
  }
}

/* -------------------- NOTES PAGE -------------------- */

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final keys = provider.keys();

    final filtered = keys.where((k) {
      final note = provider.box.get(k);
      return note['title']
          .toString()
          .toLowerCase()
          .contains(search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditNotePage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: filtered.isEmpty
          ? const Center(child: Text('No notes yet'))
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final key = filtered[i];
                final note = provider.box.get(key);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(note['title']),
                    subtitle: Text(
                      note['content'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => provider.remove(key),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditNotePage(
                          noteKey: key,
                          note: note,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/* -------------------- EDIT NOTE PAGE -------------------- */

class EditNotePage extends StatefulWidget {
  final String? noteKey;
  final Map? note;

  const EditNotePage({super.key, this.noteKey, this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController title;
  late TextEditingController content;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.note?['title'] ?? '');
    content = TextEditingController(text: widget.note?['content'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: content,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (widget.noteKey == null) {
                  provider.add(title.text, content.text);
                } else {
                  provider.update(
                      widget.noteKey!, title.text, content.text);
                }
                Navigator.pop(context);
              },
              child: const Text('Save Note'),
            )
          ],
        ),
      ),
    );
  }
}
