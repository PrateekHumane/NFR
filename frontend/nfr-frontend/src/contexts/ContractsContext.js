import React, {useContext} from 'react';
import { Web3Context } from 'contexts/Web3Context';
import {web3} from "services";
import { NFRAddress } from 'constants/ContractAddresses'
const NFRJson = require('constants/NFR.json')

// import NFRJson from 'constants/NFR.json'

export const ContractsContext = React.createContext({});

export const ContractsProvider = ({ children }) => {

    const { walletAddress } = useContext(Web3Context);

    const NFRContract = new web3.eth.Contract(NFRJson.abi, NFRAddress, {from:walletAddress, gasPrice: '20000000000'});

    return (
        <ContractsContext.Provider
            value={{
                NFRContract
            }}
        >
            {children}
        </ContractsContext.Provider>
    );
};
