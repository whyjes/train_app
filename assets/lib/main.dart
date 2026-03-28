import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      // 修正点 1：将 .fromSeed 改为 ColorScheme.fromSeed
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    home: TrainSearchPage(),
  ));
}

class TrainSearchPage extends StatefulWidget {
  @override
  _TrainSearchPageState createState() => _TrainSearchPageState();
}

class _TrainSearchPageState extends State<TrainSearchPage> {
  List<List<dynamic>> allData = [];
  List<List<dynamic>> displayData = [];
  String statusMessage = "正在加载数据...";

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final customFile = File('${directory.path}/my_train_data.csv');

      String rawData;
      if (await customFile.exists()) {
        rawData = await customFile.readAsString();
        setState(() => statusMessage = "已加载自定义数据库");
      } else {
        try {
          rawData = await rootBundle.loadString("assets/data.csv");
          setState(() => statusMessage = "使用内置数据库");
        } catch (e) {
          setState(() => statusMessage = "错误：未找到初始数据文件");
          return;
        }
      }
      _processCsvData(rawData);
    } catch (e) {
      setState(() => statusMessage = "初始化失败: $e");
    }
  }

  void _processCsvData(String rawString) {
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawString);
    setState(() {
      if (listData.length > 1) {
        allData = listData.sublist(1);
      } else {
        allData = listData;
      }
      displayData = [];
    });
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() => displayData = []);
      return;
    }
    String upQuery = query.toUpperCase();
    setState(() {
      displayData = allData.where((row) {
        String colA = row.isNotEmpty ? row[0].toString().toUpperCase() : "";
        String colB = row.length > 1 ? row[1].toString() : "";
        return colA.contains(upQuery) || colB.contains(query);
      }).toList();
    });
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      File selectedFile = File(result.files.single.path!);
      String content = await selectedFile.readAsString();
      final directory = await getApplicationDocumentsDirectory();
      final savedFile = File('${directory.path}/my_train_data.csv');
      await savedFile.writeAsString(content);
      _processCsvData(content);
      setState(() => statusMessage = "数据库更新成功！");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('列车车次查询'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettings(),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: TextField(
              onChanged: _handleSearch,
              decoration: InputDecoration(
                labelText: '输入车次、车站',
                hintText: '例如: G340 或 武汉',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: displayData.isEmpty
                ? Center(child: Text(allData.isEmpty ? "数据库为空" : "输入关键词开始查询"))
                : ListView.builder(
                    itemCount: displayData.length,
                    itemBuilder: (context, index) {
                      var row = displayData[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: ListTile(
                          title: Text(row[0].toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(row.length > 1 ? row[1].toString() : ""),
                          trailing: Text(
                            row.length > 2 ? row[2].toString() : "",
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text("系统状态"),
              subtitle: Text(statusMessage),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.file_upload),
              title: Text("上传新 CSV 数据库"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadFile();
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
