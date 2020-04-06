import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Mapas extends StatefulWidget {

  String idViagem;

  Mapas({this.idViagem});

  @override
  _MapasState createState() => _MapasState();
}

class _MapasState extends State<Mapas> {

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _marcadores={};
  CameraPosition _posicaoCamera = CameraPosition(
      target: LatLng(-23.562436,-46.655005),
      zoom: 18
  );
  Firestore _db = Firestore.instance;

  _onMapCreated(GoogleMapController controller){
    _controller.complete(controller);
  }

  _adicionarMarcador(LatLng latLng)async{

    List<Placemark> listaEndereco = await Geolocator()
        .placemarkFromCoordinates(latLng.latitude, latLng.longitude);
    if(listaEndereco != null && listaEndereco.length>0){
      Placemark endereco = listaEndereco[0];
      String rua = endereco.thoroughfare;

      print("Local clicado" + latLng.toString());
      Marker _localSelecionado = Marker(
          markerId: MarkerId("marcador -${latLng.latitude} -${latLng.longitude}"),
          position: latLng,
          infoWindow: InfoWindow(
              title: rua
          )
      );
      setState(() {
        _marcadores.add(_localSelecionado);
        //salva no firebase
        Map<String,dynamic> viagem = Map();
        viagem["titulo"] = rua;
        viagem["latitude"] = latLng.latitude;
        viagem["longitude"] = latLng.longitude;
        _db.collection("viagens")
        .add( viagem );
      });

    }


  }
  _movimentarCamera() async{
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        _posicaoCamera
      )
    );
  }

  _adicionarListenerLcalizacao(){
    var geolocator = Geolocator();
    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10
    );
    geolocator.getPositionStream(locationOptions)
    .listen((Position position){

      setState(() {
        _posicaoCamera = CameraPosition(
            target: LatLng(position.latitude,position.longitude),
          zoom: 18
        );
        _movimentarCamera();
      });

    });
  }

  _recuperaViagemParaID(String idViagem) async{

    if(idViagem != null){
      //exibir marcador para id da viagem

      DocumentSnapshot documentSnapshot = await _db.collection("viagens")
          .document(idViagem)
          .get();

      var dados = documentSnapshot.data;
      String titulo = dados["titulo"];
      LatLng latLng = LatLng(
      dados["latitude"],
      dados["longitude"]
      );

      setState(() {
        Marker _localSelecionado = Marker(
            markerId: MarkerId("marcador -${latLng.latitude} -${latLng.longitude}"),
            position: latLng,
            infoWindow: InfoWindow(
                title: titulo
            )
        );
        _marcadores.add(_localSelecionado);
        _posicaoCamera = CameraPosition(
          target: latLng,
          zoom: 18
        );
        _movimentarCamera();
      });

    }else{
      _adicionarListenerLcalizacao();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //_adicionarListenerLcalizacao();
    _recuperaViagemParaID(widget.idViagem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa"),
      ),
      body: Container(
        child: GoogleMap(
          markers: _marcadores,
          mapType: MapType.normal,
          onMapCreated: _onMapCreated,
          initialCameraPosition: _posicaoCamera,
          onLongPress: _adicionarMarcador,
          //myLocationEnabled: true,
        ),
      ),
    );
  }
}
