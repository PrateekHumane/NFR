import React, { useEffect, useState } from 'react';

export const Web3Context = React.createContext({});

export const Web3Provider= ({ children }) => {

    const [walletAddress, setWallet] = useState("");
    // const [web3, setWeb3] = useState(null);

    useEffect(() => {
        function handleAccountsChanged(accounts) {
            if (accounts.length === 0) {
                console.log('Please connect to MetaMask.');
            } else if (walletAddress !== accounts[0]) {
                setWallet(accounts[0]);
            }
        }

        try {
            window.ethereum.on('accountsChanged', handleAccountsChanged);
            window.ethereum.request({ method: 'eth_accounts' }).then(handleAccountsChanged).catch(console.error);

        } catch (error) {
            console.error(error);
        }
    }, [walletAddress]);


    // useEffect(() => {
    //     const currentWeb3 = new Web3(Web3.givenProvider || 'http://localhost:9545');
    //     setWeb3(currentWeb3);
    // }, [web3]);

    return (
        <Web3Context.Provider
            value={{
                walletAddress
            }}
        >
            {children}
        </Web3Context.Provider>
    );
};
