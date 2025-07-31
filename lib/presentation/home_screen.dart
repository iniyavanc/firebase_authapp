import 'dart:io';
import 'package:auth_app/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Box filesBox = Hive.box('filesBox');
  List<Map<String, String>> localFiles = [];

  @override
  void initState() {
    super.initState();
    _loadLocalFiles();
  }

  Future<void> _loadLocalFiles() async {
    final storedFiles = filesBox.values
        .cast<Map>()
        .map((e) => Map<String, String>.from(e))
        .toList();

    setState(() {
      localFiles = storedFiles;
    });
  }

  Future<void> _uploadFileLocally() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      final fileName = path.basename(pickedFile.path);

      final appDir = await getApplicationDocumentsDirectory();
      final savedFile = await pickedFile.copy('${appDir.path}/$fileName');

      await filesBox.add({'name': fileName, 'path': savedFile.path});

      _loadLocalFiles();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File saved locally')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file selected')));
    }
  }

  void _previewImage(String filePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Image.file(File(filePath), fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _deleteLocalFile(int index) async {
    final fileData = localFiles[index];
    final file = File(fileData['path']!);

    if (await file.exists()) {
      await file.delete();
    }
    await filesBox.deleteAt(index);
    _loadLocalFiles();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('File deleted')));
  }

  Future<void> _downloadFile(String filePath, String fileName) async {
    try {
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/Download');
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final newPath = '${downloadsDir.path}/$fileName';
      await File(filePath).copy(newPath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File saved to: $newPath')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Box filesBox = Hive.box('filesBox');

    Future<void> logout(BuildContext context) async {
      await Hive.box('filesBox').clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const CircleAvatar(radius: 40, backgroundImage: AssetImage('')),
            Divider(),
            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
         backgroundColor: const Color(0xFF232941),
        title: const Text('File Uploade/download',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white), 

        actions: [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: _uploadFileLocally,
                ),
              ],
            ),
          ),
          Expanded(
            child: localFiles.isEmpty
                ? const Center(child: Text("No local files"))
                : ListView.builder(
                    itemCount: localFiles.length,
                    itemBuilder: (context, index) {
                      final file = localFiles[index];
                      final fileName = file['name']!;
                      final filePath = file['path']!;
                      final isImage =
                          fileName.endsWith('.jpg') ||
                          fileName.endsWith('.jpeg') ||
                          fileName.endsWith('.png');

                      return ListTile(
                        title: Text(
                          fileName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () =>
                                  _downloadFile(filePath, fileName),
                            ),
                            if (isImage)
                              IconButton(
                                icon: const Icon(Icons.preview),
                                onPressed: () => _previewImage(filePath),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteLocalFile(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
