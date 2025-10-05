import 'package:flutter/material.dart';
import 'package:maps_google_v2/api_services/api_services.dart';
import 'package:maps_google_v2/current_address/google_maps_screen.dart';
import 'package:maps_google_v2/location_permission_handler.dart';
import 'package:maps_google_v2/models/get_places.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  TextEditingController searchPlaceController = TextEditingController();
  GetPlaces getPlaces = GetPlaces();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.green, title: Text("location")),

      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(
          children: [
            //TextField para ingresar el nombre de un lugar o ubicacion
            TextField(
              controller: searchPlaceController,
              decoration: InputDecoration(hintText: "Search Place..."),
              onChanged: (String value) {
                // ignore: avoid_print
                print(value.toString());
                ApiServices().getPlaces(value.toString()).then((value) {
                  setState(() {
                    getPlaces = value;
                  });
                });
              },
            ),

            //Lista de resultados
            Visibility(
              visible: searchPlaceController.text.isEmpty ? false : true,
              child: Expanded(
                child: ListView.builder(
                  itemCount: getPlaces.predictions?.length ?? 0,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        // ignore: avoid_print
                        print(
                          //Pintamos en consola el ID del lugar
                          "PlaceId: ${getPlaces.predictions?[index].placeId}",
                        );
                        //Obtenemos las Coordenadas del lugar por su ID
                        ApiServices().getCoordinatesFromPlaceId(getPlaces.predictions?[index].placeId??"").then((value){
                          
                          //Al presionar el destino nos dirirge a un mapa con las Coordenadas obtenidas anteriormente
                          Navigator.push(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (context) => GoogleMapsScreen(
                                lat: value.result?.geometry?.location?.lat??0.0,
                                lng: value.result?.geometry?.location?.lng??0.0,
                              ),
                            ),
                          );
                        }).onError((error, StackTrace){
                          // ignore: avoid_print
                          print("Error ${error.toString()}");
                        });
                      },
                      leading: Icon(Icons.location_on),
                      title: Text(
                        //muestra los lugares que encuentra el modelo de lo que se escribio en el text field
                        getPlaces.predictions![index].description.toString(),
                      ),
                    );
                  },
                ),
              ),
            ),

            Visibility(
              visible: searchPlaceController.text.isEmpty ? true : false,
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    determinePosition()
                        .then((value) {
                          Navigator.push(
                            
                            context,
                            MaterialPageRoute(
                              builder: (context) => GoogleMapsScreen(
                                lat: value.latitude,
                                lng: value.longitude,
                              ),
                            ),
                          );
                        })
                        .onError((error, stackTrace) {
                          // ignore: avoid_print
                          print('LOCATION ERROR: ${error.toString()}');
                        });
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.my_location, color: Colors.green),
                      SizedBox(width: 5),
                      Text('Current location'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
