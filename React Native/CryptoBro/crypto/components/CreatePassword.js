import React, { useState, useContext, useEffect } from 'react';
import { ScrollView, View,  Text, StyleSheet, Button, Modal, TextInput } from 'react-native';
import Slider from '@react-native-community/slider';
import { DataContext } from '../contexts/DataContext';

import { useNavigation } from '@react-navigation/native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const CreatePassword = () => {
    const [passwordLength, setPasswordLength] = useState(6);
    const [numberOfDigits, setNumberOfDigits] = useState(0);
    const [numberOfCaps, setNumberOfCaps] = useState(0);
    const [numberOfSymbols, setNumberOfSymbols] = useState(0);
    const [generatedPassword, setGeneratedPassword] = useState('');
    const [modalVisible, setModalVisible] = useState(false);
    const [application, setApplication] = useState('');
    const [email, setEmail] = useState('');

    const { data, updateData } = useContext(DataContext);
    const navigation = useNavigation();

    useEffect(() => {
        console.log(data)
    }, [])

    const storeData = async (value) => {
      try {
        const jsonValue = JSON.stringify(value);
        await AsyncStorage.setItem('@storage_Key', jsonValue);
        console.log('Saved data')
      } catch (e) {
        console.error('Error saving data', e);
      }
    };

    const handleDataUpdate = (application, eMail) => {
        if(data){
            console.log(data, 'From create')
            const newData = [...data, { application, eMail, password: generatedPassword }];
            updateData(newData);
            storeData(newData);
        } else {
            tempArray = []
            tempArray.push({application: application, eMail: eMail, password: generatedPassword})
            updateData(tempArray);
            storeData(tempArray)
        }

    };

    const decrementNumberOfDigits = () => {
        if(numberOfDigits >= 1){
            setNumberOfDigits(numberOfDigits - 1);
        }
    };

    const incrementNumberOfDigits = () => {
        setNumberOfDigits(numberOfDigits + 1);
    };

    const decrementNumberOfCaps = () => {
        if(numberOfCaps >= 1){
            setNumberOfCaps(numberOfCaps - 1);
        }
    };

    const incrementNumberOfCaps = () => {
        setNumberOfCaps(numberOfCaps + 1);
    };

    const decrementNumberOfSymbols = () => {
        if(numberOfSymbols >= 1){
            setNumberOfSymbols(numberOfSymbols - 1);
        }
    };

    const incrementNumberOfSymbols = () => {
        setNumberOfSymbols(numberOfSymbols + 1);
    };

    const generatePassword = () => {
        const chars = 'abcdefghijklmnopqrstuvwxyz';
        const caps = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        const digits = '0123456789';
        const symbols = '!@#$%^&*()_+{}|:;<>,.?~-=[]"\'';
        let result = '';
        if(passwordLength < (numberOfCaps + numberOfDigits + numberOfSymbols)){
            return
        }

        for (let i = 0; i < passwordLength - (numberOfCaps + numberOfDigits + numberOfSymbols); i++) {
            result += chars.charAt(Math.floor(Math.random() * chars.length));
        }

        for (let i = 0; i < numberOfDigits; i++) {
            result += digits.charAt(Math.floor(Math.random() * digits.length));
        }

        for (let i = 0; i < numberOfCaps; i++) {
            result += caps.toUpperCase().charAt(Math.floor(Math.random() * caps.length));
        }

        for (let i = 0; i < numberOfSymbols; i++) {
            result += symbols.charAt(Math.floor(Math.random() * symbols.length));
        }

        console.log(result)
        const shuffle = str => [...str].sort(()=>Math.random()-.5).join('');
        console.log(shuffle(result))
        setGeneratedPassword(shuffle(result))
    }

    const makeModalVisible = () => {
        setModalVisible(true);
    };

    const savePassword = () => {
        setModalVisible(false);
        setApplication('');
        setEmail('');
        handleDataUpdate(application, email)
    };

    const closeModal = () => {
        setModalVisible(false);
        setApplication('');
        setEmail('');
    };

    useEffect(() => {
        const unsubscribe = navigation.addListener('focus', () => {});
        return unsubscribe;
    }, [data, navigation]);

    return (
        <ScrollView contentContainerStyle={styles.container}>
            <Text style={styles.h1}>Create a password</Text>
            <Text style={styles.h2}>Build a strong password by using the properties below</Text>

            <Text style={styles.passwordLengthLabel}>Length of password: {passwordLength}</Text>

            <Slider
                style={{width: '80%', height: 40}}
                minimumValue={6}
                maximumValue={20}
                minimumTrackTintColor="#FFFFFF"
                maximumTrackTintColor="#000000"
                step={1}
                value={passwordLength}
                onValueChange={setPasswordLength}
            />

            <Text style={styles.labelsNumbers}>Number of digits: {numberOfDigits}</Text>
            <View style={styles.numberButtons}>
                <Button title='Decrease' onPress={decrementNumberOfDigits}></Button>
                <Button title='Increase' onPress={incrementNumberOfDigits}></Button>
            </View>

            <Text style={styles.labelsNumbers}>Number of capitals: {numberOfCaps}</Text>
            <View style={styles.numberButtons}>
                <Button title='Decrease' onPress={decrementNumberOfCaps}></Button>
                <Button title='Increase' onPress={incrementNumberOfCaps}></Button>
            </View>

            <Text style={styles.labelsNumbers}>Number of symbols: {numberOfSymbols}</Text>
            <View style={styles.numberButtons}>
                <Button title='Decrease' onPress={decrementNumberOfSymbols}></Button>
                <Button title='Increase' onPress={incrementNumberOfSymbols}></Button>
            </View>

            <View style={styles.generateSafeButtons}>
                <Button title='Generate' onPress={generatePassword}></Button>
                <Button title='Safe' onPress={makeModalVisible}></Button>
            </View>
            <View style={styles.generatedPasswordView}>
                <Text style={styles.passwordText}>{ generatedPassword }</Text>
            </View>




            {/* Modal */}
            <Modal visible={modalVisible} animationType="slide" transparent={true}>
                <View style={styles.modalContainer}>
                <View style={styles.modalContent}>
                    <Text style={styles.modalTitle}>Save Password</Text>
                    <Text style={styles.modalLabel}>Application:</Text>
                    <TextInput
                    style={styles.modalInput}
                    value={application}
                    onChangeText={setApplication}
                    placeholder="Enter application name"
                    />
                    <Text style={styles.modalLabel}>Email:</Text>
                    <TextInput
                    style={styles.modalInput}
                    value={email}
                    onChangeText={setEmail}
                    placeholder="Enter email"
                    />
                    <View style={styles.modalButtons}>
                    <Button title="Save" onPress={savePassword} />
                    <Button title="Close" onPress={closeModal} />
                    </View>
                </View>
                </View>
            </Modal>
        </ScrollView>
    );
};

const styles = StyleSheet.create({
    // Your existing styles
    container: {
        alignItems: 'center',
        padding: 20, // You might want to add some padding
        paddingBottom: 100
    },
    h1: {
         fontWeight: 'bold',
         fontSize: 30
     },
     h2: {
         fontWeight: 'bold',
         fontSize: 26,
         color: 'rgba(0, 0, 0, 0.4)', // Blue with 70% opacity
         marginTop: '5%'
     },
     label: {
         fontSize: 16,
         marginBottom: '10%',
     },
     value: {
         fontSize: 20,
         fontWeight: 'bold',
         marginBottom: '20%',
     },
     slider: {
         width: '80%',
     },
     passwordLengthLabel: {
         marginTop: '15%'
     },
     numberButtons: {
         flexDirection: 'row', // Display the text elements in a row
         justifyContent: 'space-between', // Distribute space between the text elements
         padding: '3%',
         width: '60%',
     },
     labelsNumbers: {
         marginTop: '4%'
     },
     generateSafeButtons: {
         flexDirection: 'row', // Display the text elements in a row
         justifyContent: 'space-between', // Distribute space between the text elements
         padding: '5%',
         width: '60%',
     },
     generatedPasswordView: {
         marginTop: '7%',
         backgroundColor: 'rgba(0, 0, 0, 1)',
         width: '100%',
         justifyContent: 'center', // Center vertically
         alignItems: 'center', // Center horizontally
         minHeight: '12%'
     },
     passwordText: {
         color: 'rgba(255, 255, 255, 1)',
     },
     modalContainer: {
         flex: 1,
         justifyContent: 'center',
         alignItems: 'center',
       },
       modalContent: {
         backgroundColor: 'white',
         padding: 20,
         borderRadius: 10,
       },
       modalTitle: {
         fontSize: 18,
         fontWeight: 'bold',
         marginBottom: 10,
       },
       modalLabel: {
         fontSize: 16,
         marginBottom: 5,
       },
       modalInput: {
         borderWidth: 1,
         borderColor: '#ccc',
         borderRadius: 5,
         padding: 8,
         marginBottom: 10,
       },
       modalButtons: {
         flexDirection: 'row',
         justifyContent: 'space-around',
       },
 });

export default CreatePassword;
