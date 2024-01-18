import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View } from 'react-native';
import * as FileSystem from 'expo-file-system';
import Papa from 'papaparse';
import { useEffect } from 'react';
const testCsv = require('./test.json');

export default function App() {

  const readCSV = async () => {
    try {
     console.log(testCsv)
    } catch (error) {
      console.error('Error reading CSV file:', error);
    }
  };

  useEffect(() => {
    readCSV();
  })

  return (
    <View style={styles.container}>
      <Text>Open up App.tsx to start working on your app!</Text>
      <StatusBar style="auto" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
