import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:minhasviagens/Mapas.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _controller = StreamController<QuerySnapshot>.broadcast();
  Firestore _db = Firestore.instance;

  _adcionarListenerViagens()async{
    final stream = await _db.collection("viagens")
        .snapshots();

    stream.listen((dados){
      _controller.add(dados);
    });

  }

  _abrirMapa(String idViagem){

    Navigator.push(context, MaterialPageRoute(builder: (context) => Mapas( idViagem: idViagem, )));

  }
  _excluirViagem(String idViagem){
    _db.collection("viagens").document(idViagem).delete();

  }
  _adicionarLocal(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=> Mapas()));
  }

@override
  void initState() {
    // TODO: implement initState
    super.initState();
    _adcionarListenerViagens();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Minhas viagens"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xff0066cc),
        child: Icon(Icons.add),

        onPressed: (){
          _adicionarLocal();
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot){
          switch(snapshot.connectionState){
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
            case ConnectionState.done:
              QuerySnapshot querySnapshot = snapshot.data;
              List<DocumentSnapshot> viagens = querySnapshot.documents.toList();
              return Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                        itemCount: viagens.length,
                        itemBuilder: (contex,index){
                         DocumentSnapshot item = viagens[index];
                         String titulo = item["titulo"];
                         String idViagem = item.documentID;
                          return GestureDetector(
                            onTap: (){
                              _abrirMapa( idViagem );
                            },
                            child: Card(
                              child: ListTile(
                                title: Text(titulo),
                                /*trailing: recebe um Widget que será exibido do lado
                      * direito, normalmente usado para exibir ações que podem
                      * ser feitas dentro da lista*/
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: (){
                                        _excluirViagem( idViagem );
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )

                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                    ),
                  )
                ],
              );

              break;
          }
        },
      ),
    );
  }
}
