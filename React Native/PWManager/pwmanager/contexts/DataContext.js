import React, { createContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const DataContext = createContext();

export const DataProvider = ({ children }) => {
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

  useEffect(() => {
    loadData();
  }, []); // The empty array means this effect runs once on mount

  return (
    <DataContext.Provider value={{ data, updateData }}>
      {children}
    </DataContext.Provider>
  );
};
