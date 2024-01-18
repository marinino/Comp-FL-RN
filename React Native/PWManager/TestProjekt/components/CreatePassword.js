import React, { useState, useContext, useEffect } from 'react';
import { View, Text, StyleSheet, Button, Modal, TextInput } from 'react-native';
import Slider from '@react-native-community/slider';
import { DataContext } from './../App';
import { useNavigation } from '@react-navigation/native';

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

    const handleDataUpdate = (application, eMail) => {
        // Handle data updates in CreatePassword
        data.push({application: application, eMail: eMail, password: generatedPassword})

        updateData(data);
    };

    // Function to decrement the counter
    const decrementNumberOfDigits = () => {
        if(numberOfDigits >= 1){
            setNumberOfDigits(numberOfDigits - 1);
        }
    };

    const incrementNumberOfDigits = () => {
        setNumberOfDigits(numberOfDigits + 1);
    };

    // Function to decrement the counter
    const decrementNumberOfCaps = () => {
        if(numberOfCaps >= 1){
            setNumberOfCaps(numberOfCaps - 1);
        }
    };

    const incrementNumberOfCaps = () => {
        setNumberOfCaps(numberOfCaps + 1);
    };

    // Function to decrement the counter
    const decrementNumberOfSymbols = () => {
        if(numberOfSymbols >= 1){
            setNumberOfSymbols(numberOfSymbols - 1);
        }
    };

    const incrementNumberOfSymbols = () => {
        setNumberOfSymbols(numberOfSymbols + 1);
    };

    const generatePassword = () => {

        const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        const digits = '0123456789';
        const symbols = '!@#$%^&*()_+{}|:;<>,.?~-=[]"\''; // Add or modify symbols as needed
      
        let result = '';

        if(passwordLength < (numberOfCaps + numberOfDigits + numberOfSymbols)){
            return
        }

         // Generate x characters
        for (let i = 0; i < passwordLength - (numberOfCaps + numberOfDigits + numberOfSymbols); i++) {
            result += chars.charAt(Math.floor(Math.random() * chars.length));
        }

        // Generate y digits
        for (let i = 0; i < numberOfDigits; i++) {
            result += digits.charAt(Math.floor(Math.random() * digits.length));
        }

        // Generate z capital letters
        for (let i = 0; i < numberOfCaps; i++) {
            result += chars.toUpperCase().charAt(Math.floor(Math.random() * chars.length));
        }

        // Generate m symbols
        for (let i = 0; i < numberOfSymbols; i++) {
            result += symbols.charAt(Math.floor(Math.random() * symbols.length));
        }

        setGeneratedPassword(result)
    }

    const makeModalVisible = () => {
        setModalVisible(true);
      };
    
      const savePassword = () => {
        // Handle saving the password with the entered application and email
        // Reset the modal state
        setModalVisible(false);
        setApplication('');
        setEmail('');
        console.log(application, email)
        handleDataUpdate(application, email)
      };
    
      const closeModal = () => {
        // Reset the modal state
        setModalVisible(false);
        setApplication('');
        setEmail('');
      };

      useEffect(() => {
        const unsubscribe = navigation.addListener('focus', () => {
          // The screen is focused
          // Call any action to update the screen
        });
    
        // Cleanup the listener when the component is unmounted
        return unsubscribe;
      }, [data, navigation]);

    return (
        <View style={styles.container}>
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

        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        alignItems: 'center',
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