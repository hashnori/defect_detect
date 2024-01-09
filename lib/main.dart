import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? controller;
  bool isModelReady = false;
  List<dynamic> recognitions = [];

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: 'assets/product_classifier_model.tflite',
      labels: 'assets/labels.txt',
    );
    setState(() {
      isModelReady = true;
    });
  }

  Future<void> initCamera() async {
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    await controller!.initialize();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    controller?.dispose();
    Tflite.close();
    super.dispose();
  }

  Future<void> runModelOnFrame() async {
    if (controller != null) {
      XFile image = await controller!.takePicture();
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 2,
        threshold: 0.2,
        asynch: true,
      );

      setState(() {
        this.recognitions = recognitions!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Demo'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CameraPreview(controller!),
            ),
            ElevatedButton(
              onPressed: isModelReady ? runModelOnFrame : null,
              child: Text('Run Model'),
            ),
            Text('Predictions: $recognitions'),
          ],
        ),
      ),
    );
  }
}
