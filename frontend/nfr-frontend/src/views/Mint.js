import React, {useContext} from 'react';
import {ContractsContext} from "../contexts/ContractsContext";

const Mint = (props) => {

    const {NFRContract} = useContext(ContractsContext);

    const doMint = async () => {
        try {
            await NFRContract.methods.mintPack([47, 49, 44, 45]).send({gas: 3000000});
        } catch (error) {
            console.log(error);
        }
    }

    return (
        <div>
            <button onClick={doMint}>
                mint it
            </button>
        </div>
    );
}

export default Mint;
