import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/flashcard_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FlashcardAdapter());
  await Hive.openBox<Flashcard>('flashcards');
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlashcardQuizApp',
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const FlashcardHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FlashcardHomePage extends StatefulWidget {
  const FlashcardHomePage({super.key});

  @override
  _FlashcardHomePageState createState() => _FlashcardHomePageState();
}

class _FlashcardHomePageState extends State<FlashcardHomePage> {
  late Box<Flashcard> flashcardBox;
  int _currentIndex = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    flashcardBox = Hive.box<Flashcard>('flashcards');
  }

  void _nextCard() {
    setState(() {
      _showAnswer = false;
      _currentIndex = (_currentIndex + 1) % flashcardBox.length;
    });
  }

  void _prevCard() {
    setState(() {
      _showAnswer = false;
      _currentIndex =
          (_currentIndex - 1 + flashcardBox.length) % flashcardBox.length;
    });
  }

  void _shuffleCard() {
    setState(() {
      _showAnswer = false;
      _currentIndex = (flashcardBox.length > 1)
          ? (List.generate(flashcardBox.length, (i) => i)..shuffle()).first
          : 0;
    });
  }

  void _addCard() {
    TextEditingController questionCtrl = TextEditingController();
    TextEditingController answerCtrl = TextEditingController();
    List<TextEditingController> optionCtrls =
        List.generate(4, (_) => TextEditingController());
    String type = 'single';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInnerState) {
        return AlertDialog(
          title: const Text('Add Flashcard'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: questionCtrl,
                    decoration: const InputDecoration(labelText: 'Question')),
                TextField(
                    controller: answerCtrl,
                    decoration: const InputDecoration(labelText: 'Answer')),
                DropdownButton<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(
                        value: 'single', child: Text('Single Answer')),
                    DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
                  ],
                  onChanged: (value) {
                    setInnerState(() {
                      type = value!;
                    });
                  },
                ),
                if (type == 'mcq')
                  ...List.generate(4, (index) {
                    return TextField(
                      controller: optionCtrls[index],
                      decoration:
                          InputDecoration(labelText: 'Option ${index + 1}'),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  if (questionCtrl.text.isNotEmpty &&
                      answerCtrl.text.isNotEmpty) {
                    List<String>? options;
                    if (type == 'mcq') {
                      options = optionCtrls
                          .map((ctrl) => ctrl.text)
                          .where((opt) => opt.isNotEmpty)
                          .toList();
                    }
                    flashcardBox.add(Flashcard(
                      question: questionCtrl.text,
                      answer: answerCtrl.text,
                      type: type,
                      options: options,
                    ));
                    setState(() {
                      _currentIndex = flashcardBox.length - 1;
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flashcard added')));
                  }
                },
                child: const Text('Add')),
          ],
        );
      }),
    );
  }

  void _editCard() {
    if (flashcardBox.isEmpty) return;

    Flashcard current = flashcardBox.getAt(_currentIndex)!;
    TextEditingController questionCtrl =
        TextEditingController(text: current.question);
    TextEditingController answerCtrl =
        TextEditingController(text: current.answer);
    String type = current.type;
    List<TextEditingController> optionCtrls = List.generate(
      4,
      (i) => TextEditingController(
        text: current.options != null && i < current.options!.length
            ? current.options![i]
            : '',
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInnerState) {
        return AlertDialog(
          title: const Text('Edit Flashcard'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: questionCtrl,
                    decoration: const InputDecoration(labelText: 'Question')),
                TextField(
                    controller: answerCtrl,
                    decoration: const InputDecoration(labelText: 'Answer')),
                DropdownButton<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(
                        value: 'single', child: Text('Single Answer')),
                    DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
                  ],
                  onChanged: (value) {
                    setInnerState(() {
                      type = value!;
                    });
                  },
                ),
                if (type == 'mcq')
                  ...List.generate(4, (index) {
                    return TextField(
                      controller: optionCtrls[index],
                      decoration:
                          InputDecoration(labelText: 'Option ${index + 1}'),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  if (questionCtrl.text.isNotEmpty &&
                      answerCtrl.text.isNotEmpty) {
                    List<String>? options;
                    if (type == 'mcq') {
                      options = optionCtrls
                          .map((ctrl) => ctrl.text)
                          .where((opt) => opt.isNotEmpty)
                          .toList();
                    }
                    flashcardBox.putAt(
                        _currentIndex,
                        Flashcard(
                          question: questionCtrl.text,
                          answer: answerCtrl.text,
                          type: type,
                          options: options,
                        ));
                    setState(() {});
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flashcard updated')));
                  }
                },
                child: const Text('Save')),
          ],
        );
      }),
    );
  }

  void _deleteCard() {
    if (flashcardBox.isEmpty) return;
    flashcardBox.deleteAt(_currentIndex);
    setState(() {
      _showAnswer = false;
      if (_currentIndex >= flashcardBox.length) {
        _currentIndex = flashcardBox.isEmpty ? 0 : flashcardBox.length - 1;
      }
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Flashcard deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final cards = flashcardBox.values.toList();
    final current = (cards.isNotEmpty && _currentIndex < cards.length)
        ? cards[_currentIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Quiz App'),
        actions: [
          IconButton(
              icon: const Icon(Icons.shuffle),
              tooltip: 'Shuffle',
              onPressed: _shuffleCard),
          IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: _editCard),
          IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
              onPressed: _deleteCard),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add),
        tooltip: 'Add Flashcard',
      ),
      body: flashcardBox.isEmpty
          ? const Center(child: Text("No flashcards. Tap + to add one."))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              key: ValueKey(_showAnswer),
                              children: [
                                Text(
                                  current!.question,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(height: 20),
                                if (_showAnswer)
                                  current.type == 'mcq'
                                      ? Column(
                                          children: current.options!
                                              .map((opt) => ListTile(
                                                    leading: Icon(
                                                      opt == current.answer
                                                          ? Icons.check_circle
                                                          : Icons
                                                              .radio_button_unchecked,
                                                      color:
                                                          opt == current.answer
                                                              ? Colors.green
                                                              : null,
                                                    ),
                                                    title: Text(opt),
                                                  ))
                                              .toList(),
                                        )
                                      : Text(
                                          current.answer,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => _showAnswer = !_showAnswer),
                            icon: Icon(_showAnswer
                                ? Icons.visibility_off
                                : Icons.visibility),
                            label: Text(
                                _showAnswer ? "Hide Answer" : "Show Answer"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                          onPressed: _prevCard,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Previous")),
                      ElevatedButton.icon(
                          onPressed: _nextCard,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text("Next")),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
