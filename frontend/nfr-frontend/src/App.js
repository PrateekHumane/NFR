// import Web3 from 'web3'
import {useEffect, useState} from 'react';
import {Web3Provider} from 'contexts/Web3Context';
import {AuthProvider} from 'contexts/AuthContext';
import PrivateRoute from 'components/PrivateRoute';

const App = () => {
    const [ethereumEnabled, setEthereumEnabled] = useState(false);

    useEffect(() => {
        // if ethereum is injected
        setEthereumEnabled(typeof window.ethereum !== 'undefined');
    }, [ethereumEnabled]);


    if (!ethereumEnabled)
        return (
            <p>install metamask</p>
        );
    else
        return (
            <AuthProvider>
                <Web3Provider>
                    <PrivateRoute/>
                </Web3Provider>
            </AuthProvider>
        );

}

export default App;
