import React, { useEffect, useState } from 'react';
import { onAuthStateChanged } from "firebase/auth";
import {auth} from 'services';

export const AuthContext = React.createContext({});

export const AuthProvider= ({ children }) => {

    const [user, setUser] = useState(null);

    useEffect(() => {
        onAuthStateChanged(auth, setUser);
    }, []);

    return (
        <AuthContext.Provider
            value={{
                user
            }}
        >
            {children}
        </AuthContext.Provider>
    );
};
