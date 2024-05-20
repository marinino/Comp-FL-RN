import { StyleSheet, View, Image, TouchableOpacity } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { createContext, useState, useEffect } from 'react';

import HomeScreen from './components/HomeScreen';
import CreatePassword from './components/CreatePassword';

const homeIcon = require('./assets/icons8-home-512.png');
const createPasswordIcon = require('./assets/icons8-add-100.png');

const Tab = createBottomTabNavigator();

export const DataContext = createContext();

const App = () => {
  const [data, setData] = useState([]);

  const updateData = (newData) => {
    setData(newData);
    storeData(newData); // Save the updated data to AsyncStorage
  };

  const storeData = async (value) => {
    try {
      const jsonValue = JSON.stringify(value);
      await AsyncStorage.setItem('@storage_Key', jsonValue);
    } catch (e) {
      console.error('Error saving data', e);
    }
  };

  // Load data from storage when the app loads
  useEffect(() => {
    const loadData = async () => {
      try {
        const jsonValue = await AsyncStorage.getItem('@storage_Key');
        if (jsonValue != null) {
          const loadedData = JSON.parse(jsonValue);
          setData(loadedData); // Update the state with loaded data
        }
      } catch (e) {
        console.error('Error loading data', e);
      }
    };

    loadData();
  }, []); // The empty array means this effect runs once on mount

  return (
    <DataContext.Provider value={{ data, updateData }}>
      <NavigationContainer>
        <Tab.Navigator
          screenOptions={({ route }) => ({
            tabBarIcon: ({ focused, color, size }) => {
              let iconName;

              if (route.name === 'HomeScreen') {
                iconName = homeIcon;
              } else if (route.name === 'CreatePassword') {
                iconName = createPasswordIcon;
              }

              return <Image source={iconName} style={{ width: size, height: size }} />;
            },
            tabBarActiveTintColor: 'tomato',
            tabBarInactiveTintColor: 'gray',
          })}
        >
          <Tab.Screen name="HomeScreen" component={HomeScreen} />
          <Tab.Screen name="CreatePassword" component={CreatePassword} />
        </Tab.Navigator>
      </NavigationContainer>
    </DataContext.Provider>
  );
};

const styles = StyleSheet.create({
  bottomBar: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    backgroundColor: '#f0f0f0',
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 60,
    borderTopWidth: 1,
    borderTopColor: '#ccc',
  },
  heading: {
    fontSize: 24,
    fontWeight: 'bold',
    marginTop: '10%',
    marginLeft: '5%',
  },
  buttonText: {
    fontSize: 16,
    marginLeft: 8, // Adjust the margin as needed
  },
  buttonIcon: {
    width: 24,
    height: 24,
    marginRight: 8, // Adjust the margin as needed
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
  },
});

export default App;
