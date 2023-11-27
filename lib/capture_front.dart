import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_svg/svg.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class CaptureFrontDocumentScreen extends StatefulWidget {
  const CaptureFrontDocumentScreen({Key? key}) : super(key: key);

  @override
  State<CaptureFrontDocumentScreen> createState() =>
      _CaptureFrontDocumentScreenState();
}

class _CaptureFrontDocumentScreenState
    extends State<CaptureFrontDocumentScreen> {
  late CameraController cameraController;
  bool photoTaken =
      false; // Variable para controlar si se ha tomado la foto o no
  late XFile capturedImage;
  late File _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  // Función para solicitar permiso de la cámara
  Future<void> _requestCameraPermission() async {
    final PermissionStatus permissionStatus = await Permission.camera.request();
    if (permissionStatus.isGranted) {
      _initializeCamera();
    } else {
      // Manejar el caso en el que el permiso no se concede
    }
  }

  // Función para capturar automáticamente una foto después del enfoque
  void _capturePhotoAfterFocus(int seconds) async {
    if (seconds != 0) {
      await Future.delayed(Duration(seconds: seconds)); // Espera 3 segundos
    }

    if (cameraController.value.isTakingPicture) {
      return;
    }

    try {
      final XFile picture = await cameraController.takePicture();

      // Check image orientation and rotate if needed
      // final img.Image capturedImg =
      //     img.decodeImage(File(picture.path).readAsBytesSync())!;
      // img.Image orientedImage = capturedImg;

      // if (orientedImage.height > orientedImage.width) {
      //   final maxWidth = capturedImg.width;
      //   final halfHeight = capturedImg.height ~/ 2;
      //   orientedImage = img.copyCrop(capturedImg,
      //       x: 0, y: 0, width: maxWidth, height: halfHeight);

      //   //orientedImage = img.copyRotate(capturedImg, angle: 90);
      //   File(picture.path).writeAsBytesSync(img.encodeJpg(orientedImage));
      // }

      // Aquí se maneja la foto capturada
      setState(() {
        photoTaken = true; // Establecer que se ha tomado la foto
        capturedImage = picture;
      });

      await cameraController.unlockCaptureOrientation();

      print('Foto capturada: ${picture.path}');
    } catch (e) {
      // Manejar cualquier error que pueda ocurrir al tomar la foto
      print('Error al capturar la foto: $e');
    }
  }

  // Función para inicializar la cámara después de obtener los permisos
  void _initializeCamera() async {
    final cameras = await availableCameras();

    cameraController =
        CameraController(cameras[0], ResolutionPreset.max, enableAudio: false);

    await cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        //_capturePhotoAfterFocus(2); // Llama a la función de captur foto después de la inicialización
      });
    }).catchError((e) {
      print(e);
    });
  }

  void _handleTap(TapDownDetails details) {
    if (!cameraController.value.isInitialized) {
      return;
    }

    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final Offset tapPosition = details.localPosition;

    final x = tapPosition.dx / width;
    final y = tapPosition.dy / height;

    cameraController.setExposurePoint(Offset(x, y));
    cameraController.setFocusPoint(Offset(x, y));
  }

  Future getImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    XFile? picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (picked != null) {
      final img.Image capturedImg =
          img.decodeImage(File(picked.path).readAsBytesSync())!;
      img.Image orientedImage = capturedImg;

      if (orientedImage.height > orientedImage.width) {
        final maxWidth = capturedImg.width;
        final halfHeight = capturedImg.height ~/ 2;
        orientedImage = img.copyCrop(capturedImg,
            x: 0, y: 0, width: maxWidth, height: halfHeight);

        orientedImage = img.copyRotate(capturedImg, angle: -90);
        File(picked.path).writeAsBytesSync(img.encodeJpg(orientedImage));
      }

      setState(() {
        photoTaken = true;
        _image = File(picked.path);
        capturedImage = picked;
      });
    }
  }

  @override
  void dispose() {
    // Se debe liberar el controlador cuando la vista se descarte
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: const Color(0xFF0E1C32),
        body: SingleChildScrollView(
          child: GestureDetector(
            onTapDown: _handleTap,
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 32, horizontal: 27),
                      child: Column(
                        children: [
                          Text(
                            'Parte delantera de tu \n identificación',
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              height: 1.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 24),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Enfoca y tomaremos la foto automáticamente',
                              maxLines: 1,
                              softWrap: true,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 27.0),
                      child: AspectRatio(
                        aspectRatio: cameraController.value.aspectRatio,
                        child: !photoTaken
                            ? CameraPreview(
                                cameraController,
                              )
                            : Image.file(File(capturedImage.path)),
                      ),
                    ),
                    const SizedBox(height: 50.0),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 27.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  size: 22.0,
                                  Icons.check_sharp,
                                  color: Color(0xFF24DE9C),
                                ),
                                SizedBox(width: 10.0),
                                Text(
                                  'Encuadra bien la imagen',
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 22.0),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 27.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  size: 22.0,
                                  Icons.check_sharp,
                                  color: Color(0xFF24DE9C),
                                ),
                                SizedBox(width: 10.0),
                                Text(
                                  'Asegúrate de que la información sea visible',
                                  maxLines: 2,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 250),
                  ],
                ),
                Positioned(
                  left: 0,
                  bottom: 60,
                  right: 0,
                  child: GestureDetector(
                      onTap: () {
                        //getImageFromCamera();
                        _capturePhotoAfterFocus(
                            0); // Llama al método para capturar la foto desde el obturador
                      },
                      child: SvgPicture.asset(
                          'assets/imgs/screens/setupid/camera-shutter.svg')),
                ),
                photoTaken
                    ? Positioned(
                        left: MediaQuery.of(context).size.width / 2 - 27,
                        bottom: MediaQuery.of(context).size.height / 2 - 40,
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF24DE9C),
                          size: 54.0,
                        ))
                    : const SizedBox()
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox(height: 20);
    }
  }
}
