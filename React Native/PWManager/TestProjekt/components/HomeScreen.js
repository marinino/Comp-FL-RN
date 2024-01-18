import React, { useState, useContext, useEffect } from 'react';
import { View, Text, StyleSheet, SectionList, Modal, Button } from 'react-native';
import { useNavigation, useFocusEffect } from '@react-navigation/native';
import { DataContext } from './../App';

const HomeScreen = () => {

  const [isModalVisible, setModalVisible] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const navigation = useNavigation();
  const { data } = useContext(DataContext);
  const [forceRender, setForceRender] = useState(0); // State variable to force re-render

  useEffect(() => {
    navigation.addListener('focus', () => {
      // The screen is focused
      // No need to call updateData here, as it will be triggered in the useFocusEffect
      groupDataByFirstLetter();
      handleForceRender()
    });
  }, [navigation]);

  useFocusEffect(
    React.useCallback(() => {
      // The screen is focused
      // Call any action to update the screen
      // In this example, let's just log a message to the console
      console.log('HomeScreen is focused. Data has changed.' + data.length);
      groupDataByFirstLetter();
      
    }, [data, forceRender])
  );

  const handleForceRender = () => {
    // Update the state variable to force a re-render
    setForceRender((prev) => prev + 1);
  };

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

  // Function to group data by the first letter
  const groupDataByFirstLetter = () => {
    console.log('Grouped by first letter')
    const groupedData = {};

    data.forEach(item => {
      const firstLetter = item.application.charAt(0).toUpperCase();

      if (!groupedData[firstLetter]) {
        groupedData[firstLetter] = [];
      }

      groupedData[firstLetter].push(item);
    });

    return groupedData;
  };

  const groupedData = groupDataByFirstLetter();
  const sections = Object.keys(groupedData).map(application => ({
    title: application,
    data: groupedData[application],
  }));

  return (
    <View style={styles.container}>
      <View style={styles.containerElementsSideBySide}>
        <Text style={styles.textAmountPasswords}>10 Passwords</Text>
        <Text style={styles.textAmountStrengths}>3 Strong</Text>
        <Text style={styles.textAmountStrengths}>2 Mediocore</Text>
      </View>

      <SectionList
            style={styles.list}
            sections={sections}
            renderItem={renderItem}
            renderSectionHeader={renderSectionHeader}
            keyExtractor={(item) => item.application}
      />

        {/* Modal */}
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
        marginTop: '0%', // Set the top margin to 40% of the screen height
        backgroundColor: '#4db8ff', // Set the background color for the container
        width: '100%', // Set the width to 100% of the screen width
    },
    item: {
        padding: 16,
        borderBottomWidth: 1,
        borderBottomColor: '#ccc',
        backgroundColor: 'white', // Set the background color for each list item
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
      flexDirection: 'row', // Display the text elements in a row
      justifyContent: 'space-between', // Distribute space between the text elements
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
