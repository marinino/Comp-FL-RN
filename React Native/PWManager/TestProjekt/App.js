import { StyleSheet,  View, Image, TouchableOpacity } from 'react-native';
import { NavigationContainer, useNavigation  } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

import React, { createContext, useState } from 'react';


import HomeScreen from './components/HomeScreen';
import CreatePassword from './components/CreatePassword';

const homeIcon = require('./assets/icons8-home-512.png');
const createPasswordIcon = require('./assets/icons8-add-100.png');

const Tab = createBottomTabNavigator();

export const DataContext = createContext();



const App = () => {

  const [data, setData] = useState([
    { application: 'Amazon', eMail: 'example@mail.com', password: '123456' },
    { application: 'EBay', eMail: 'example@mail.com', password: '123456' },
    { application: 'Uni', eMail: 'example@mail.com', password: '123456' },
    // Add more items as needed
  ]);

  const updateData = (newData) => {
    setData(newData);
  };

  return (
    
      <DataContext.Provider value={{ data, updateData }}>
        <NavigationContainer>
          <Tab.Navigator>
            <Tab.Screen name="HomeScreen" component={HomeScreen} />
            <Tab.Screen name="CreatePassword" component={CreatePassword}/>
            {/* Add more screens as needed */}
          </Tab.Navigator>
          <BottomNavigationBar/>
        </NavigationContainer>
      </DataContext.Provider>
      
 
    
  );
}

const BottomNavigationBar = () => {

  const navigation = useNavigation();

  return (
    <View style={styles.bottomBar}>
      <TouchableOpacity onPress={() => navigation.navigate('HomeScreen')} style={styles.button}>
        <Image source={homeIcon} style={styles.buttonIcon} />
      </TouchableOpacity>
      <TouchableOpacity onPress={() => navigation.navigate('CreatePassword')} style={styles.button}>
        <Image source={createPasswordIcon} style={styles.buttonIcon} />
      </TouchableOpacity>
      {/* Add more tabs as needed */}
    </View>
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
    fontWeight:'bold',
    marginTop: '10%',
    marginLeft: '5%'
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
  }
});

export default App;


