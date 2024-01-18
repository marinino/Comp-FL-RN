import Ionicons from 'react-native-vector-icons/Ionicons';
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import SharesScreen from './screens/SharesScreen';
import NewsScreen from './screens/NewsScreen';

const Tab = createBottomTabNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <Tab.Navigator
        screenOptions={({ route }) => ({
          tabBarIcon: ({ focused, color, size }) => {
            let iconName;
           if (route.name === 'News') {
              iconName = focused ? 'newspaper' : 'newspaper-outline'; // Example icon names for newsletters
            } else if (route.name === 'Shares') {
              iconName = focused ? 'bar-chart' : 'bar-chart-outline'; // Example icon names for graphs
            }
            return <Ionicons name={iconName} size={size} color={color} />;
          },
        })}
      >
        <Tab.Screen name="Shares" component={SharesScreen} />
        <Tab.Screen name="News" component={NewsScreen} />
      
      </Tab.Navigator>
    </NavigationContainer>
  );
}
