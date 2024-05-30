import React, { useEffect, useState } from "react";
import { Text, View, StyleSheet, ScrollView, TouchableOpacity, Linking } from "react-native"

export default function NewsScreen(){
  
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const openURL = (url) => {
    Linking.canOpenURL(url)
      .then((supported) => {
        if (supported) {
          Linking.openURL(url);
        } else {
          console.log("Don't know how to open URI: " + url);
        }
      })
      .catch(err => console.error("An error occurred", err));
  };

  useEffect(() => {
    startTime = new Date()
    fetch("https://newsdata.io/api/1/news?apikey=pub_3479125dc2aa95ff324e8db0dcba1f6dc723f&q=crypto%20news",{
      method: "GET",
    })   
      .then((response) => {
          if (!response.ok) {
            throw new Error("Network response was not ok");
          }
          return response.json();
      })
      .then(data => {
          currentTime = new Date()
           console.log('Time for req: ' + (currentTime - startTime))
          setData(data.results);
          setLoading(false);
      })
      .catch(error => {
          setError(error);
          setLoading(false);
      });
  }, []);

  if (loading) {
      return <Text>Loading...</Text>;
  }
  if (error) {
      return <Text>Error: {error.message}</Text>;
  }

  return(
    <ScrollView style={styles.container}>
      {data.map((item, index) => (
        <TouchableOpacity key={item.article_id} onPress={() => openURL(item.link)}>
          <View style={styles.row}>
            <Text style={styles.cell}>{item.title}</Text>
          </View>
        </TouchableOpacity>
      ))}
    </ScrollView>
     
  );
}

// Supported by CHATGPT from here
const styles = StyleSheet.create({
    container: {
      flex: 1,
    },
    row: {
      flexDirection: "row",
      justifyContent: "space-around",
      alignItems: "center",
      padding: 10,
      borderBottomWidth: 1,
      borderBottomColor: "#ddd",
    },
    cell: {
      flex: 1,
      textAlign: "center",
    },
    modalView: {
      margin: 20,
      backgroundColor: "white",
      borderRadius: 20,
      padding: 10,
      alignItems: "center",
      shadowColor: "#000",
      shadowOffset: {
        width: 0,
        height: 2
      },
      shadowOpacity: 0.25,
      shadowRadius: 3.84,
      elevation: 5
    },
    webview: {
      height: "80%",
      width: "100%"
    },
});