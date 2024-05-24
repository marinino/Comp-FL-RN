import React, { useState, useContext, useEffect } from 'react';
import { View, Text, StyleSheet, SectionList, Modal, Button } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { DataContext } from '../contexts/DataContext'; // Adjust the path if necessary
import AsyncStorage from '@react-native-async-storage/async-storage';

const HomeScreen = () => {
  const [isModalVisible, setModalVisible] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const navigation = useNavigation();
  const { data, updateData } = useContext(DataContext); // Correctly use the DataContext
  const [sections, setSections] = useState([]);

  useEffect(() => {
    const groupedData = groupDataByFirstLetter(data);
    const newSections = Object.keys(groupedData).sort().map(application => ({
      title: application,
      data: groupedData[application],
    }));
    setSections(newSections);
  }, [data]);

  const renderItem = ({ item }) => (
    <View style={styles.item} onTouchEnd={() => handleItemPress(item)}>
      <Text style={styles.itemText}>{item.application}</Text>
    </View>
  );

  const handleItemPress = (item) => {
    setSelectedItem(item);
    setModalVisible(true);
  };

  const closeModal = () => {
    setModalVisible(false);
    setSelectedItem(null);
  };

  const renderSectionHeader = ({ section: { title } }) => (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionHeaderText}>{title}</Text>
    </View>
  );

  const groupDataByFirstLetter = (pData) => {
    const groupedData = {};

    pData.forEach(item => {
      const firstLetter = item.application.charAt(0).toUpperCase();

      if (!groupedData[firstLetter]) {
        groupedData[firstLetter] = [];
      }

      groupedData[firstLetter].push(item);
    });

    Object.keys(groupedData).forEach(letter => {
      groupedData[letter].sort((a, b) => a.application.localeCompare(b.application));
    });

    return groupedData;
  };

  return (
    <View style={styles.container}>
      <View style={styles.containerElementsSideBySide}>
        <Text style={styles.textAmountPasswords}>10 Passwords</Text>
        <Text style={styles.textAmountStrengths}>3 Strong</Text>
        <Text style={styles.textAmountStrengths}>2 Mediocre</Text>
      </View>

      <SectionList
        style={styles.list}
        sections={sections}
        renderItem={renderItem}
        renderSectionHeader={renderSectionHeader}
        keyExtractor={(item) => item.application}
      />

      <Modal visible={isModalVisible} animationType="slide" transparent={true}>
        <View style={styles.modalContainer}>
          <View style={styles.modalContent}>
            <Text style={styles.fontBold}>E-Mail:</Text>
            <Text style={styles.modalText}>{selectedItem ? selectedItem.eMail : ''}</Text>
            <Text style={styles.fontBold}>Password:</Text>
            <Text style={styles.modalText}>{selectedItem ? selectedItem.password : ''}</Text>
            <Button title="Close" onPress={closeModal} />
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    marginTop: '0%',
    backgroundColor: '#4db8ff',
    width: '100%',
  },
  item: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#ccc',
    backgroundColor: 'white',
  },
  itemText: {
    fontSize: 24
  },
  sectionHeader: {
    padding: 8,
    backgroundColor: '#e0e0e0',
  },
  sectionHeaderText: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  list: {
    marginTop: '20%'
  },
  containerElementsSideBySide: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: '20%',
    width: '100%',
    padding: 16,
  },
  textAmountPasswords: {
    fontSize: 24
  },
  textAmountStrengths: {
    fontSize: 16,
  },
  modalContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  modalContent: {
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 10,
  },
  fontBold: {
    fontWeight: 'bold'
  },
  modalText: {
    marginBottom: '3%'
  }
});

export default HomeScreen;
